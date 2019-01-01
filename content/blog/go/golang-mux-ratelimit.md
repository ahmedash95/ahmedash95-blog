---
title: "GoLang API rate limit"
date: 2018-02-13T12:49:33+02:00
---

A few days ago I published my first go package [GoLang Rate Limit](https://github.com/ahmedash95/ratelimit).

the purpose of this package is to prevent DDos attack and control the rate of traffic sent or received on the network. In this article I will describe how to implement it with [gorilla/mux](https://github.com/gorilla/mux).

## So let's start with writing a simple API
```golang
package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	// Initialize Router
	router := mux.NewRouter()
	router.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello"))
	})
	// Start Server
	log.Println("Starting server on port http://localhost:8000")
	http.ListenAndServe(":8000", router)
}
```

So I just made a new **Router** that returns `Hello` word.

the next step is to implement the rate limit module

#### First let's create a variable to hold a ratelimit object in the main function
the ratelimit will receive 1 request per second
```golang
// hold the rate limit object
var ratelimit rl.Limit

func main() {
    // Create ratelimit Object
    ratelimit = rl.CreateLimit("1r/s")

    // Initialize Router
    router := mux.NewRouter()
    router.Handle("/",
    // ....
```
then we will add 2 more methods one for the middleware and another one to validate the limit
```golang
func isValidRequest(l rl.Limit, key string) bool {
    // check if key exists
	_, ok := l.Rates[key]
	if !ok {
		return true
    }
    // check if the hits reached the allowed number of requests
	if l.Rates[key].Hits == l.MaxRequests {
		return false
	}
	return true
}
```
```golang
func RateLimitMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := "127.0.0.1" // use ip or user agent or any key you want
		if !isValidRequest(ratelimit, ip) {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		ratelimit.Hit(ip)
		h.ServeHTTP(w, r)
	})
}
```

now let's change the index handler with new middleware method
```golang
// from
router.HandleFunc("/",
    func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("Hello"))
	})
// to
router.Handle("/",
    RateLimitMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello"))
    })))
```

so the above code implemented the `RateLimitMiddleware` and pass it the `handlerFunc`

## The final result is
```golang
package main

import (
	"log"
	"net/http"

	rl "github.com/ahmedash95/ratelimit"

	"github.com/gorilla/mux"
)

// hold the rate limit object
var ratelimit rl.Limit

func main() {
	// Create ratelimit
	ratelimit = rl.CreateLimit("1r/s")
	// Initialize Router
	router := mux.NewRouter()
	router.Handle("/",
		RateLimitMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Write([]byte("Hello"))
		})))
	// Start Server
	log.Println("Starting server on port http://localhost:8000")
	http.ListenAndServe(":8000", router)
}

// Middleware
func RateLimitMiddleware(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ip := "127.0.0.1" // use ip or user agent any key you want
		if !isValidRequest(ratelimit, ip) {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		ratelimit.Hit(ip)
		h.ServeHTTP(w, r)
	})
}

func isValidRequest(l rl.Limit, key string) bool {
	_, ok := l.Rates[key]
	if !ok {
		return true
	}
	if l.Rates[key].Hits == l.MaxRequests {
		return false
	}
	return true
}
```

### Now we will test what we did by using [Siege](https://github.com/JoeDog/siege)
> Siege is an open source regression test and benchmark utility. It can stress test a single URL with a user defined number of simulated users

```bash
$   siege -b -r 1 -c 10 "http://localhost:8000"
```

<img src="/images/blog/go/golang-mux-ratelimit/siege-benchmarking.png">

The above command sends a 10 requests in the same second so the result is 1 accepted request and 9 blocked requests with 503 response code


# Conclusion

I tried to simplify how to implement a simple rate limit but you can use it for any case that needs ratelimit, also there is a leaky-bucket algorithm for rate limit implemented in go by [UBER](https://github.com/uber-go/ratelimit) you can try it too instead of blocking traffic.

**Note:** if you see anything wrong with the package or article please share your knowledge by posting a comment with your notes