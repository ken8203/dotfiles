// Command outpost-rex-forward lets the Rex app reach the Rex server on an
// Outpost instance.
//
// Usage: outpost-rex-forward HOST PORT REMOTE_SOCKET
//
// ssh forwards the server's Unix socket to a private local one, and this
// command serves it on 127.0.0.1:PORT, the only kind of address the Rex app
// takes. Rex trusts whoever reaches the socket and accepts any Host header,
// so the port alone would let any local account, or a web page through DNS
// rebinding, drive outpost. A request passes only if it names this exact
// address, carries no Origin (browsers always send one on a WebSocket), and
// offers the token in HOST.token. Rex clients send the user part of a host's
// address as the subprotocol rex.as.<user>, so outpost-rex puts the token
// there; it is dropped before the server sees it.
package main

import (
	"context"
	"crypto/subtle"
	"log"
	"net"
	"net/http"
	"net/http/httputil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var apps = []string{"https://outpost-api.dcard.io", "https://outpost-ssh.dcard.io"}

func main() {
	if len(os.Args) != 4 {
		log.Fatal("usage: outpost-rex-forward HOST PORT REMOTE_SOCKET")
	}
	host, port, remote := os.Args[1], os.Args[2], os.Args[3]
	home, err := os.UserHomeDir()
	if err != nil {
		log.Fatal(err)
	}
	state := filepath.Join(home, "Library/Application Support/outpost-rex-forward")
	local := filepath.Join(state, host+".sock")
	address := "127.0.0.1:" + port

	go tunnel(host, local, remote)

	proxy := &httputil.ReverseProxy{
		Rewrite: func(r *httputil.ProxyRequest) {
			r.Out.URL.Scheme = "http"
			r.Out.URL.Host = "rex"
		},
		Transport: &http.Transport{
			DialContext: func(ctx context.Context, _, _ string) (net.Conn, error) {
				return (&net.Dialer{}).DialContext(ctx, "unix", local)
			},
		},
	}
	gate := func(w http.ResponseWriter, r *http.Request) {
		token, err := os.ReadFile(filepath.Join(state, host+".token"))
		if err != nil || r.Host != address || r.Header.Get("Origin") != "" ||
			!takeToken(r.Header, "rex.as."+strings.TrimSpace(string(token))) {
			log.Printf("refused %s %s", r.RemoteAddr, r.URL.Path)
			http.Error(w, "forbidden", http.StatusForbidden)
			return
		}
		proxy.ServeHTTP(w, r)
	}
	log.Fatal(http.ListenAndServe(address, http.HandlerFunc(gate)))
}

// takeToken reports whether the request offers want as a WebSocket
// subprotocol, and removes it from the offer.
func takeToken(h http.Header, want string) bool {
	var kept []string
	found := false
	for _, v := range h.Values("Sec-WebSocket-Protocol") {
		for _, p := range strings.Split(v, ",") {
			p = strings.TrimSpace(p)
			if subtle.ConstantTimeCompare([]byte(p), []byte(want)) == 1 {
				found = true
			} else if p != "" {
				kept = append(kept, p)
			}
		}
	}
	if found {
		h.Set("Sec-WebSocket-Protocol", strings.Join(kept, ", "))
	}
	return found
}

// tunnel keeps ssh forwarding the remote socket to local. A lapsed Cloudflare
// Access login would send ssh's proxy into a browser login on every retry, so
// it waits for outpost-up to renew the login instead.
func tunnel(host, local, remote string) {
	for {
		if loggedIn() {
			cmd := exec.Command("ssh", "-N", "-o", "BatchMode=yes", "-o", "ExitOnForwardFailure=yes",
				"-o", "StreamLocalBindUnlink=yes", "-L", local+":"+remote, host)
			cmd.Stderr = os.Stderr
			if err := cmd.Run(); err != nil {
				log.Printf("ssh: %v", err)
			}
		}
		time.Sleep(10 * time.Second)
	}
}

func loggedIn() bool {
	for _, app := range apps {
		if exec.Command("cloudflared", "access", "token", "--app", app).Run() != nil {
			return false
		}
	}
	return true
}
