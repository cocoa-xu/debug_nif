#include <spawn.h>
#include <stdio.h>
#include <string.h>
#include <sys/wait.h>
#include <erl_nif.h>
#include <errno.h>
#include <vector>
#include <string>

extern char **environ;
static ERL_NIF_TERM error(ErlNifEnv *env, const char *msg)
{
    ERL_NIF_TERM atom = enif_make_atom(env, "error");
    ERL_NIF_TERM reason;
    unsigned char * ptr;
    size_t len = strlen(msg);
    if ((ptr = enif_make_new_binary(env, len, &reason)) != NULL) {
        strcpy((char *)ptr, msg);
        return enif_make_tuple2(env, atom, reason);
    } else {
        ERL_NIF_TERM msg_term = enif_make_string(env, msg, ERL_NIF_LATIN1);
        return enif_make_tuple2(env, atom, msg_term);
    }
}

static int get_string(ErlNifEnv *env, ERL_NIF_TERM term, std::string &var)
{
    unsigned len;
    int ret = enif_get_list_length(env, term, &len);

    if (!ret)
    {
        ErlNifBinary bin;
        ret = enif_inspect_binary(env, term, &bin);
        if (!ret)
        {
            return 0;
        }
        var = std::string((const char *)bin.data, bin.size);
        return ret;
    }

    var.resize(len + 1);
    ret = enif_get_string(env, term, &*(var.begin()), var.size(), ERL_NIF_LATIN1);

    if (ret > 0)
    {
        var.resize(ret - 1);
    }
    else if (ret == 0)
    {
        var.resize(0);
    }
    else
    {
    }

    return ret;
}

static int get_list(ErlNifEnv* env, ERL_NIF_TERM list, std::vector<std::string>& var)
{
    unsigned int length;
    if (!enif_get_list_length(env, list, &length)) {
        return 0;
    }
    var.reserve(length);
    ERL_NIF_TERM head, tail;

    while (enif_get_list_cell(env, list, &head, &tail))
    {
        std::string elem;
        if (!get_string(env, head, elem)) {
            return 0;
        }
        var.push_back(elem);
        list = tail;
    }
    return 1;
}

static ERL_NIF_TERM run_shell(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    ERL_NIF_TERM ret_term;
    char err_msg[256] = {'\0'};
    std::vector<std::string> args;
    
    if (!get_list(env, argv[0], args)) {
        return error(env, "Invalid arguments");
    }

    size_t num_args = args.size() + 1;
    const char ** c_args = (const char **)enif_alloc(sizeof(const char *) * num_args);
    for (size_t i = 0; i < num_args; i++) {
        c_args[i] = args[i].c_str();
    }
    c_args[num_args - 1] = nullptr;

    pid_t pid;
    int status = posix_spawn(&pid, c_args[0], NULL, NULL, (char *const *)c_args, environ);
    if (status == 0) {
        if (waitpid(pid, &status, 0) != -1) {
            if (WIFEXITED(status)) {
                int return_value = WEXITSTATUS(status);
                ret_term = enif_make_tuple2(env, enif_make_atom(env, "ok"), enif_make_int(env, return_value));
            } else {
                ret_term = error(env, "WIFEXITED failed");
            }
        } else {
            snprintf(err_msg, sizeof(err_msg), "waitpid: %s", strerror(errno));
            ret_term = error(env, err_msg);
        }
    } else {
        snprintf(err_msg, sizeof(err_msg), "posix_spawn: %s", strerror(status));
        ret_term = error(env, err_msg);
    }

    enif_free((void *)c_args);
    return ret_term;
}

static int on_load(ErlNifEnv* env, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_reload(ErlNifEnv*, void**, ERL_NIF_TERM)
{
    return 0;
}

static int on_upgrade(ErlNifEnv*, void**, void**, ERL_NIF_TERM)
{
    return 0;
}

static ErlNifFunc nif_functions[] = {
    {"run_shell", 1, run_shell, ERL_NIF_DIRTY_JOB_IO_BOUND}
};

ERL_NIF_INIT(debug_nif, nif_functions, on_load, on_reload, on_upgrade, NULL);
