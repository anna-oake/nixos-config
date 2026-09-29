#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

/* One line to a unix socket. Used so a keybind does not start quickshell. */
int main(int argc, char **argv) {
    if (argc != 3)
        return 2;

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0)
        return 1;

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    if (strlen(argv[1]) >= sizeof(addr.sun_path))
        return 1;
    memcpy(addr.sun_path, argv[1], strlen(argv[1]));

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0)
        return 1;

    size_t len = strlen(argv[2]);
    if (write(fd, argv[2], len) != (ssize_t)len || write(fd, "\n", 1) != 1)
        return 1;

    close(fd);
    return 0;
}
