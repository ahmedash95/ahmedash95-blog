---
title: "Write your first GoLang app with unit tests and code coverage"
date: 2018-02-07T01:48:54+02:00
---

Go is a compiled, statically typed programming language created by Google.

before starting I will assume that you are installed Go and printed a hello world . if you didn't do that yet install Go on your machine from [here](https://golang.org/doc/install).

What I will discuss/share with u here is how we could write a simple app that sum two integers with a [TDD](https://en.wikipedia.org/wiki/Test-driven_development) and [Code Coverage](https://en.wikipedia.org/wiki/Code_coverage).

# Step 1 : Starting a new Go Project

I will create a simple `main.go` and `main_test.go` file, in **Go** when you want to write a tests for your project you write the file name followed by `_test.go` so our directory structure will be

```bash
- $Project_Path
    - main.go
    - main_test.go
```

# Step 2 : Write our first unit test file

Now because of [TDD](https://en.wikipedia.org/wiki/Test-driven_development) we will write test case first then run it to get a failed test case

```golang
package main

import (
	"testing"
)

func Test_Sum(t *testing.T){
	total := Sum(1,2)
	if total != 3 {
		t.Errorf("Sum was incorrect, got: %d, want: %d.", total, 3)
	}
}
```

now from terminal run `$ go test` you will get the output like below

```bash
./main_test.go:8:11: undefined: Sum
FAIL    _/Users/ash/tmp/go [build failed]
```

we need to fix that failed test by writing a sum function in the `main.go` file

```golang
package main

func Sum(a int, b int) int {
	return 0
}
```

then run the test again and we will get a different error message
```bash
--- FAIL: Test_Sum (0.00s)
        main_test.go:10: Sum was incorrect, got: 0, want: 3.
FAIL
exit status 1
FAIL    _/Users/ash/tmp/go      0.012s
```

now we now that our method is defined but doesn't work as expected so let's make it green by updating the `Sum()` method in our `main.go` file

```golang
package main

func Sum(a int, b int) int {
	return a + b
}
```

then let's run the test again to get a pass test

```bash
PASS
ok      _/Users/ash/tmp/go      0.012s
```

**Great** Now let's make our `main.go` works as a real app by implementing a cli interface

```go
package main

import (
	"fmt"
)

func main() {
	var err error
	var n1, n2 int
	fmt.Print("Enter first number: ")
	_, err = fmt.Scanf("%d", &n1)
	fmt.Print("\nEnter second number: ")
	_, err = fmt.Scanf("%d", &n2)
	if err != nil {
		panic(err)
	}

	fmt.Printf("\nResult is : %d\n", Sum(n1, n2))
}

func Sum(a int, b int) int {
	return a + b
}
```
Let's explain what i did here is just defining an error variable named `err` to hold any errors when parsing the integers from console , then we start reading first number then the second and if any line of them contains none integer value we will panic with error if no errors we will print the sum of the two integers.

Now if we execute the app using `$ go run main.go`
```go
$ go run main.go

Enter first number: 1

Enter second number: 2

Result is : 3
```

**Okay** if you think we are good now i'm afraid to tell you we didn't finish yet .. tell now we wrote a nice and very simple app but we didn't know do we really covered it well or we miss something ? it might be easy to know because it's a tiny app but when you work on a small or large project we might get lost with this.

fortunately go has a great cover flag to tell us if our code covered or now

# Step 3 : Code Coverage

**From [GoLang docs](#)**

> Test coverage is a term that describes how much of a package's code is exercised by running the package's tests. If executing the test suite causes 80% of the package's source statements to be run, we say that the test coverage is 80%.

### Let's start

now let's run the `$ go test -cover` to get the coverage value
```bash
PASS
coverage: 10.0% of statements
ok      _/Users/ash/tmp/go      0.009s
```
**OMG** we just cover 10% of our code only !!. but this result isn't good enough, It must be a better way that helping us visualize this result.

go has a nice test command flag called `-coverprofile` which is a file that holds the collected statistics so we can study them in more detail.

so let's run our test again with the new flag

```bash
$ go test -coverprofile=coverage.out
```

now you will find a new file in your project path `coverage.out` contains the below lines
```bash
mode: set
$PROJECT_PATH/main.go:7.13,14.16 7 0
$PROJECT_PATH/main.go:18.2,18.47 1 0
$PROJECT_PATH/main.go:14.16,15.13 1 0
$PROJECT_PATH/main.go:21.28,23.2 1 1
```

I know it's not enough yet .. but guess what ;) Go has a command to visualize the statistics in `HTML` file

```bash
$ go tool cover -html=coverage.out
```

the above command will open a browser window contains your code with red and green syntax highlighting


![code-coverage-screenshot](/images/blog/go/write-your-first-go-app-with-unit-tests-and-code-coverage/code-coverage-screenshot.png)


**Oh** now we know that we didn't test our main function. okay let's write tests for it

# Step 4 : Write testable code

Now we know that we need to cover and write tests for the `main()` function but our code is not testable and we need to decouple a few things

```
- move the std input reading to separated method
- write tests for the reading method
```

#### Step A : Separate the reading method

in `main.go` file we will create a method called `Read()` that takes a io.Reader `interface{}` and return the value

```go
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

func main() {
	var err error
	var n1, n2 int

	// create a buffer
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Enter first number: ")
	_, err = Read(reader, "%d\n", &n1)
	if err != nil {
		panic(err)
	}

	fmt.Print("Enter second number: ")
	_, err = Read(reader, "%d\n", &n2)
	if err != nil {
		panic(err)
	}

	fmt.Printf("\nResult is : %d\n", Sum(n1, n2))
}

func Read(stdIn io.Reader, format string, a ...interface{}) (int, error) {
	return fmt.Fscanf(stdIn, format, a...)
}

func Sum(a int, b int) int {
	return a + b
}
```

Now our code is a little bit decoupled and we can use different io readers, now let's write a test case for the `Read()` method which we must do first but I think this way is better
#### Step B: writing test
```golang
func Test_Read_Method(t *testing.T) {
	in, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}
	defer in.Close()

	_, err = io.WriteString(in, "3\n")
	if err != nil {
		t.Fatal(err)
	}

	_, err = in.Seek(0, os.SEEK_SET)
	if err != nil {
		t.Fatal(err)
	}

	reader := bufio.NewReader(in)
	var v int
	Read(reader, "%d", &v)

	if v != 3 {
		t.Errorf("invalid result, expected %d got %d", 3, v)
	}
}
```

our simple test method just make a temp file writing our input values into it using `io.WriteString()` method and pass it to our `Read()` method and make sure it returns the expected value

Now let's run our code coverage test again to check the result

![code-coverage-screenshot-2](/images/blog/go/write-your-first-go-app-with-unit-tests-and-code-coverage/code-coverage-screenshot-2.png)

Now we need to test our main method but we need a tiny edit in our code which is to set the reader and stdout objects so we can inject our reader into main function .. unfortunately GO doesn't have constructors so we can't use [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection)
but a `setter and getter` approach would be perfect , now let's update our code

```golang
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
)

var (
	ioReader *bufio.Reader = bufio.NewReader(os.Stdin)
	writer   io.Writer     = os.Stdout
)

func setReader(ir *bufio.Reader) {
	ioReader = ir
}

func setWriter(wr io.Writer) {
	writer = wr
}

func main() {
	var err error
	var n1, n2 int

	fmt.Print("Enter first number: ")
	_, err = Read(ioReader, "%d\n", &n1)
	if err != nil {
		panic(err)
	}

	fmt.Print("Enter second number: ")
	_, err = Read(ioReader, "%d\n", &n2)
	if err != nil {
		panic(err)
	}

	fmt.Fprintf(writer, "\nResult is : %d\n", Sum(n1, n2))
}

func Read(ir io.Reader, format string, a ...interface{}) (int, error) {
	return fmt.Fscanf(ir, format, a...)
}

func Sum(a int, b int) int {
	return a + b
}
```

we just added these few lines to help use control the in and output io

```golang
var (
	ioReader *bufio.Reader = bufio.NewReader(os.Stdin)
	writer   io.Writer     = os.Stdout
)

func setReader(ir *bufio.Reader) {
	ioReader = ir
}

func setWriter(wr io.Writer) {
	writer = wr
}
```

now let's write our test to `main()` function

```golang
func Test_Main_Method(t *testing.T) {
	in, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}
	defer in.Close()

	_, err = io.WriteString(in, "3\n4\n")
	if err != nil {
		t.Fatal(err)
	}

	_, err = in.Seek(0, os.SEEK_SET)
	if err != nil {
		t.Fatal(err)
	}

	expected := "Result is : 7"

	var b bytes.Buffer

	// run main function
	reader := bufio.NewReader(in)
	setReader(reader)
	setWriter(&b)
	main()

	actual := strings.TrimSpace(b.String())
	// _ = expected
	if actual != expected {
		t.Errorf("invalid result, expected %s got %s", actual, expected)
	}
}
```

as you see we just create an `io reader` and a `Buffer` to catch the output of our main method

Let's run our tests again

```bash
$ go test -coverprofile=coverage.out && go tool cover -html=coverage.out
```

![code-coverage-screenshot-3](/images/blog/go/write-your-first-go-app-with-unit-tests-and-code-coverage/code-coverage-screenshot-3.png)

**Yaaaay** we made a good progress , just a two `panics` to reach 100% coverage

#### Step C : Play with panics

Panics is the way to kill the running process of our app.

**From [GO-By-Example](https://gobyexample.com/panic)**

> A panic typically means something went unexpectedly wrong. Mostly we use it to fail fast on errors that shouldn’t occur during normal operation, or that we aren’t prepared to handle gracefully.

because `testing` doesn't really have the concept of "success," only failure. So it's really easy to test panics in go. we just need to tests two cases only `First` and `Second` number panics

```golang
func Test_it_panics_when_receive_un_expected_input_for_first_number(t *testing.T) {
	defer func() {
		// When no panics fire the error method
		if r := recover(); r == nil {
			t.Errorf("The main method did not panic when we enter invalid values")
		}
    }()

	in, err := ioutil.TempFile("", "")
	if err != nil {
		t.Fatal(err)
	}
	defer in.Close()

	_, err = io.WriteString(in, "ah\n4\n")
	if err != nil {
		t.Fatal(err)
	}

	_, err = in.Seek(0, os.SEEK_SET)
	if err != nil {
		t.Fatal(err)
	}

	// run main function
	reader := bufio.NewReader(in)
	setReader(reader)
	main()

}
```

So now the above test method will fail if the code running without any panics, don't forget to duplicate the same test case for the `Second number`.

Now let's try running the tests with coverage and get a `100%` code coverage


![code-coverage-screenshot-4](/images/blog/go/write-your-first-go-app-with-unit-tests-and-code-coverage/code-coverage-screenshot-4.png)


**Yaaay we did it**


# Conclusions

Write software is easy but writing a perfect one is not. in this article we explored many things hope you enjoyed it

- Unit Tests
- Test Panics
- Code Coverage statistics
- Code Coverage Reporting
- Playing with IO buffers


# Finally

I'm not an expert Gopher so If you see something wrong here please post a comment to fix it