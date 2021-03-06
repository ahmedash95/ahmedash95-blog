---
title: "Webpack, Vue, Tailwind, TypeScript for 2020"
date: 2020-01-16
affiliatelink: "https://dev.to/ahmedash95/webpack-vue-tailwind-typescript-for-2020-l9d"
---
{{< rtl/start >}}
توضيح صغير قبل ما ابدا و هو ان المقاله دي مجرد سرد لبعض المعلومات اللي قدرت افهمها عن Go Channels و ازاي ممكن استخدمها بشكل صحيح نسبياً و ازاي تكون Scalable
ويكون فيه نظام اقدر اتابع منها اداءها عامل ازاي

### ما هي Go Channels
من علي موقع GoLang نفسه بيقول
{{< ltr/start >}}
>    Channels are the pipes that connect concurrent goroutines. You can send values into channels from one goroutine and receive those values into another goroutine.
{{< ltr/end >}}

ف تقدر تقول ان الchannels هي عباره عن انابيب بتبعت رساله من ناحيه و تستقبلها من الناحيه التانيه فلما نستخدم ال go routines نقدر بسهوله نعمل asynchronous comunnications و منها انا عملت المثال العملي لل queue & workers لل email service

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/channels.jpeg)

كيف تستخدم

```go

    import (
        "fmt"
    )


    func main() {
        // Create the channel
        messages := make(chan string)

        // run a go routine to send the message
        go func() { messages <- "ping" }()
        
        // when you receive the message store it in msg variable
        msg := <-messages

        // print received message
        fmt.Println(msg)
    }

```

- ف السطر الاول احنا عرفنا ال channel وانها من نوع string 
- في السطر التاني عملنا go routine هيبعت رساله لل channel اللي اسمها messages
- السطر التالت بنستني نستقبل ال message و بعدين نطبعها ف السطر الرابع

طيب ف المثال اللي في فوق احنا مستخدمين goroutine ، لو قولنا نجرب من غير ما نستخدمه ف تبقي بالشكل ده

```go

    messages := make(chan string)

    messages <- "ping"

    msg := <-messages

    fmt.Println(msg)

```

هتظهر مشكله الـ deadlock  بسبب اننا بعتنا الرساله قبل ان يكون هناك اي مستمع و في نفس الوقت لا يوجد مساحه تخزينيه للـ channel نفسها

```bash

    fatal error: all goroutines are asleep - deadlock!

    goroutine 1 [chan send]:
    main.main()
        /tmp/sandbox676902258/prog.go:11 +0x60

```

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/channel-no-bucket.png)

بمعني ابسط احنا محتاجين نعرف الchannel بمساحه تخزينيه نقدر نخزن فيها بعض الرسائل في عدم وجود مستمع او في حاله انشغال المستمع. بشكل ابسط ممكن نحل المشكله كالتالي

```go

    messages := make(chan string,1)

    messages <- "ping"

    msg := <-messages

    fmt.Println(msg)

```

هتلاحظ اننا ف اول سطر بنعرف paramter جديد بقيمه 1 وهو ان السعه التخزينيه للقناه هيخزن قيمه واحده بس في حاله عدم وجود اي مستمع وفي المثال اللي فوق المستمع لسه هيبدا يسمع لما يوصل للسطر اللي بعده لما بنكتب
```go
    
    msg := <-messages

```

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/channel-with-bucket.png)

ف هتلاحظ اننا بنبعت الرساله و مفيش اي مستمع لسه (listener) لكن علشان احنا عرفنا ال buffer ف الchannel خزنتها و لما بدانا نسمع لاي رساله ف الخطوه 2 اخدناها من الbucket 
وطبيعي لازم نتوقع اننا لو بعتنا رسالتين ورا بعض مش هينفع لان الbuffer بيخزن قيمه واحده بس و ساعتها هيحصل deadlock

```go

    messages <- "ping"
    messages <- "pong"

    msg := <-messages

    fmt.Println(msg)

```


<h3>الطريقه الصحيحه لانشاء الـ channels</h3>

طيب الفكره هنا لو انا اتعاملت بالـ goroutines هل كل ما بيجي رساله هبعتها ف جو روتين، طيب لو عندي ترافيك كبير ؟ طيب لو حاجه وقعت او باظت هعرفها ازاي ؟ هقدر اتوسع (scale) بالطريقه دي ازاي. دي كلها اسئله بتيجي ف دماغي لما نتكلم عن ال messaging او ال async jobs. 

<p>ف خلينا نبدا بالدايجرام اللي يوضح المفروض احنا نمشي ازاي</p>
<div style="text-align:center">
    ![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/worker-queue.png" style="width:300px;)
</div>

بكل بساطه محتاجين يبقي عندنا Queue / Dispatcher والديسباتشر ده فاتح عدد x من ال workers ف انا ممكن افتح اي عدد من ال workers 
وكل ما الترافيك يزيد ممكن ازود ال workers اكتر. و بعدين ممكن اخلي ال woker عباره عن servers كل وركر ليه سيرفر مثلا بس مش هنتطرق لده دلوقتي .

هنفترض ان الترافيك اللي عندنا يخلينا نفتع 4 workers و دول هيبقو كفايه اوي 

<h3>سيكشن العملي</h3>

اول حاجه هنبدا بيها هي ال Dispatcher ، اللي من خلاله هنبعت ال jobs علشان نعملها process في ال background


```go

    //JobQueue ... a buffered channel that we can send work requests on.
    var JobQueue chan Queuable
        
    //Queuable ... interface of Queuable Job
    type Queuable interface {
        Handle() error
    }

    //Dispatcher ... worker dispatcher
    type Dispatcher struct {
        maxWorkers int
        WorkerPool chan chan Queuable
        Workers    []Worker
    }

```

اغلب المصادر اللي قابلتها كانو بيعملو الJob نوع واحد زي مثلا انه يقولك EmailJob / SMSJob / SlackJob ف انا قررت اريح دماغي و استخدم الInterface
بحيث اني اي وقت اقدر ابعت اي Struct ليه فانكشن handle و بيرجع error في حاله حدوث خطآ


الـDispatcher ليه ٣ خواص مهمه
<ul>
    <li>الـ maxWorkers: وهنا علشان الديسباتشر لما يبدا يعمل عدد ال workers ده</li>
    <li>الـ WorkerPool: كل وركر هيكون ليه pool و هيسجل نفسه فيه علشان لما الديسباتشر يوصله اي رساله يبدا يبعتها لاي pool فاضي ويشتغل عليها</li>
    <li>الـ Workers: بنسجل فيه كل وركر بنعمله علشان نقدر نقفل عدد الوركرز او نزودها بعد كدا - مش مهمه اوي -</li>
</ul>

بعد كدا هنعمل الفانشكن اللي نقولها اعملي ديسباتشر ب عدد وركرز معين و تعمله و ترجعلنا الديسباتشر ده

```go

    //NewDispatcher ... creates new queue dispatcher
    func NewDispatcher(maxWorkers int) *Dispatcher {
        // make job bucket
        if JobQueue == nil {
            JobQueue = make(chan Queuable, 10)
        }
        pool := make(chan chan Queuable, maxWorkers)
        return &Dispatcher{WorkerPool: pool, maxWorkers: maxWorkers}
    }

```

بعدين عندنا اهم ٢ فانكشن علشان يبعتو اي job جديدة لل workers اللي موجوده

```go

    //Run ... starts work of dispatcher and creates the workers
    func (d *Dispatcher) Run() {
        // starting n number of workers
        for i := 0; i < d.maxWorkers; i++ {
            worker := NewWorker(d.WorkerPool)
            worker.Start()
            // register in dispatcher's workers
            d.Workers = append(d.Workers, worker)
        }

        go d.dispatch()
    }

```

بشكل بسيط Run بتعمل ال workers و تسجلهم في ال dispatcher <strong>-هنعرف NewWorker بتعمل ايه دلوقتي-</strong>

```go

    func (d *Dispatcher) dispatch() {
        for {
            select {
            case job := <-JobQueue:
                // a job request has been received
                go func(job Queuable) {
                    // try to obtain a worker job channel that is available.
                    // this will block until a worker is idle
                    jobChannel := <-d.WorkerPool

                    // dispatch the job to the worker job channel
                    jobChannel <- job
                }(job)
            }
        }
    }
     
```

اخر ال Run احنا بنبدا goroutine بيشغل ال dispatch فانكشن

الديسباتش بتفتح infinte loop و بتبداها انها بتستي اي رساله تيجي ع ال JobQueue واول ما تيجي 
بنفتح كمان goroutine و نسحب اي pool متاح من ال WorkerPool اللي هو واحد من ال٤ ، وبعدين نبعتله ال Message/Job اللي جاتلنا دي 



طيب دلوقتي الديسباتشر قادر يبعت الرساله لل worker، طيب الوركر ده هيعمل ايه بقي 

اولا الوركر هو Struct محتواه كالتالي
```go

    //Worker ... simple worker that handles queueable tasks
    type Worker struct {
        Name       string
        WorkerPool chan chan Queuable
        JobChannel chan Queuable
        quit       chan bool
    }

```

<ul>
    <li>الـ Name: مجرد اسم هنسميه للوركر علشان نقدر نميز بينهم بسهوله بعد كدا</li>
    <li>الـ WorkerPool قولنا ان ده ال pool اللي موجود في الـ dispatcher اللي من خلاله هيبعتلنا عليه الjobs</li>
    <li>الـ JobChannel: ال messages اللي هنستقبلها من ال dispatcher. اللي هي مش بتشيل غير message واحده بس ف المره</li>
    <li>الـ quit: ده علشان لو احنا عاوزين نقفل الـ worker. في حاله اننا لو محتاجين نعمل وركرز و نقفلها دينامك حسب الترافيك</li>
</ul>

طيب فوق شويه احنا قولنا ان الديسباتشر بيعمل NewWorker و قولنا هنتكلم عليها

```go

    //NewWorker ... creates a new worker
    func NewWorker(name string, workerPool chan chan Queuable) Worker {
        return Worker{
            Name:       name,
            WorkerPool: workerPool,
            JobChannel: make(chan Queuable),
            quit:       make(chan bool) }
    }

```

الخطوه المهمه و الاخيره :D، فين الRun بتاعت الوركر 

```go

    //Start ... initiate worker to start lisntening for upcomings queueable jobs
    func (w Worker) Start() {
        go func() {
            for {
                // register the current worker into the worker queue.
                w.WorkerPool <- w.JobChannel

                select {
                case job := <-w.JobChannel:
                    // we have received a work request.
                    if err := job.Handle(); err != nil {
                        fmt.Printf("Error in job: %s\n", err.Error())
                    }
                }
            }
        }()
    }

```

بنفتح forloop و بنسجل ال worker ف الpool علي طول   و نبدا نسمع اول لاول رساله يبعتها الديسباتشر
لاحظ ان كل ما الوركر يخلص ال message بنرجع نسجلها تاني ف الpool زي السيناريو الاتي


- الديسباتشر بدا و عمل ٤ وركرز
- اول وركر بدا و سجل نفسه في الpool و مستني الرساله
- تاني وركر بدا و سجل نفسه في الpool و مستني الرساله
- وصلت رساله ف الديسباتشر سحب من WorkerPool الوركر الاول
- كدا WorkerPool فيه الوركر التاني بس لان الاول اتسحب
- وصلت رساله جديدة ف الديسباشتر سحب من البوول الوركر التاني
- بعدين الوركر الاول لسه مخلصش بس التاني خلص ف نفذ اول سطر ف الRun و سجل نفسه في البوول تاني
- بعد كدا الوركر الاول خلص و سجل نفسه تاني
- ف لما توصل رساله كدا هتتبعت للوركر التاني لانه سجل نفسه الاول 



<h3>نستخدم الكلام ده ازاي</h3>

زي ما قولنا انا هفترض انها Email Service بتبعت ايميلات و انا هـQueue ال emails دي في jobs

```go

    type Email struct {
        To      string `json:"to"`
        From    string `json:"from"`
        Subject string `json:"subject"`
        Content string `json:"content"`
    }

    func (e Email) Handle() error {
        r := rand.Intn(200)
        time.Sleep(time.Duration(r) * time.Millisecond)
        return nil
    }

```

وعندي هنا EmailService

```go

    //EmailService ... email service
    type EmailService struct {
        Queue chan queue.Queuable
    }

    //NewEmailService ... returns email service to send emails :D
    func NewEmailService(q chan queue.Queuable) *EmailService {
        service := &EmailService{
            Queue: q,
        }

        return service
    }

    func (s EmailService) Send(e Email) {
        s.Queue <- e
    }

```

وفي ال main

```go

    var QueueDispatcher *Dispatcher

    func main() {
        QueueDispatcher = NewDispatcher(4)
        QueueDispatcher.Run()

        mailService = emails.NewEmailService(JobQueue)

        r := gin.Default()
        r.GET("/email", sendEmailHandler)
        return r
    }

    func sendEmailHandler(c *gin.Context) {
        emailTo := c.Query("to")
        emailFrom := c.Query("from")
        emailSubject := c.Query("subject")
        emailContent := c.Query("content")

        email := emails.Email{
            To:      emailTo,
            From:    emailFrom,
            Subject: emailSubject,
            Content: emailContent,
        }

        mailService.Send(email)

        c.String(200, "Email will be sent soon :)")
    }

```

### نتفرج ع الكلام ده ازاي؟

من الحاجات المهمه جدا في ال async jobs انه يكون فيه اداه بتساعدنا نشوف ال jobs و ازاي بتشتغل و اداءها عامل ازاي
انا ادور علي حاجه بسيطه تكون بتعمل كدا بشكل جاهز :D ملقتش ف قررت اخوض التجربه بادوات لعبت بيها قبل كدا الا وهم **Prometues & Grafana**

### طيب اولا ماهو Prometheus؟

برومثيوس alerting & metric software بتقدر تبعت شويه احصائيات و تقدر تحط alert لكل احصائيه حسب خصائص معينه. مش دي القضيه لان استخدامنا هيبقي بسيط جدا

ما هي Grafana:
بردو هي alerting & metric بس لل databases. يعني ايه ؟ يعني Prometheus هو نظام بيساعدنا نبعت احصائيات و نخزنها و فيه نظام monitoring بسيط. و هنستخدم جرافانا علشان تقرا من prometheus و تعرض الداتا بشكل جميل جدا

طيب علشان نسخن الدنيا شويه المفروض ال dashboard هتخرج بالشكل النهائي ده

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/go-channels-init.png)

- هنعرف فيه كام Worker شغال
- فيه كام Job في Queue هيتعملهم proccess
- بنستقبل كام Job في الثانيه
- الـ duration لكل job بتخلص امتي. ف نقدر نعرف لو فيه حاجه حصلت غلط و لو الجوب بتاخد وقت طويل عن العادي


## الجزء الاول: Prometheus

محتاجين الاول نعرف نوع ال Metric اللي نقدر نستخدمها مع Prometheus و الفروقات بينهم


- الـ Counter: مقياس تراكمي يقبل القيم الموجبه و مينفعش غير انه يرجع لل صفر. يعني مثلا ممكن نعد استقبلنا كام Job او خلصنا كام Job حاجه كدا زي ال PageViews عمر ما هيكون عندك pageviews بالسالب :D لان ده غير منطقي. 
- الـ Gauge: احصائيه بتستخدم للارقام في حاله التغير. زي مثلا درجه الحراره او الـ MemoryUsage. بردو نقدر نعتبرها زي ال Concurrent User ممكن يبقي ١٠٠ و ينزل ٥٠ و يطلع ٦٠ و يرجع ١
- الـ Histogram: اعتبره المراقب نقدر نبص علي ال response size او ال request duration ف نقدر نعرف متوسط الrequests اللي بتجيلنا بنرجعها ف قد ايه
- الـ Summary: زي الهيستوجرام بالظبط بالاضافه انه ممكن يعد هو سجل كام ريكوست مثلا و يجمع القيم بتاعت ال  duration مثلا. - انا مش فاهمه اوي و مش عارف ممكن استخدمه ازاي ف لو عارف يا ريت توضح في الكومنتس ;)


## نبدا الشغل :D

```go

    package queue

    var (
        JobsProcessed  *prometheus.CounterVec
        RunningJobs    *prometheus.GaugeVec
        ProcessingTime *prometheus.HistogramVec
        RunningWorkers *prometheus.GaugeVec
    )

    var collectorContainer []prometheus.Collector

    //InitPrometheus ... initalize prometheus
    func InitPrometheus() {
        prometheus.MustRegister(collectorContainer...)
    }

    //PushRegister ... Push collectores to prometheus before inializing
    func PushRegister(c ...prometheus.Collector) {
        collectorContainer = append(collectorContainer, c...)
    }

    func InitMetrics() {
        JobsProcessed = prometheus.NewCounterVec(
            prometheus.CounterOpts{
                Namespace: "worker",
                Subsystem: "jobs",
                Name:      "processed_total",
                Help:      "Total number of jobs processed by the workers",
            },
            []string{"worker_id", "type"},
        )

        RunningJobs = prometheus.NewGaugeVec(
            prometheus.GaugeOpts{
                Namespace: "worker",
                Subsystem: "jobs",
                Name:      "running",
                Help:      "Number of jobs inflight",
            },
            []string{"type"},
        )

        RunningWorkers = prometheus.NewGaugeVec(
            prometheus.GaugeOpts{
                Namespace: "worker",
                Subsystem: "workers",
                Name:      "running",
                Help:      "Number of workers inflight",
            },
            []string{"type"},
        )

        ProcessingTime = prometheus.NewHistogramVec(
            prometheus.HistogramOpts{
                Namespace: "worker",
                Subsystem: "jobs",
                Name:      "process_time_seconds",
                Help:      "Amount of time spent processing jobs",
            },
            []string{"worker_id", "type"},
        )

        metrics.PushRegister(ProcessingTime, RunningJobs, JobsProcessed, RunningWorkers)
    }
        
```

مش محتاجه شرح كتير لانها واضحه، بشكل كبير ان احنا بنعرف ال Metrics اللي هنستخدمها مع Prometheus علشان يسجل البيانات عليها

طيب دلوقتي احنا عندنا ال Metrics و عرفناها. المفروض نقدر نشوفها بتتسجل ازاي

الطريقه اللي Prometheus بيشتغل بيها، هو اني بوفر API endpoint "/metric" و برجع منها ال collected metric data وبنقرا منها من جرافانا بعد كدا

```go
    
    r.Handle("GET", "/metrics", gin.WrapH(promhttp.Handler()))

```

تعالي نجرب :D 

```go

    JobsProcessed.WithLabelValues("Worker-1", "ahmedash.com").Inc()
    JobsProcessed.WithLabelValues("Worker-1", "ahmedash.com").Inc()

    JobsProcessed.WithLabelValues("Worker-2", "ahmedash.com").Inc()
    JobsProcessed.WithLabelValues("Worker-2", "ahmedash.com").Inc()
    JobsProcessed.WithLabelValues("Worker-2", "ahmedash.com").Inc()

```

ف هتكون النتيجه 

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/prometheus-metrics.png)

وده شكل ال Dashboard - هي مش قد كده يعني :D - 

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/prometheus-dashboard.png)
    
ف ده باختصار الطريقه اللي بيشتغل بيها، ممكن تجرب و تلعب كتير لغايه ما تقدر تفهم التفاصيل اكتر شويه بالشكل اللي يخليك تقدر تستخدمها كويس

### الجزء الثاني Grafana

الطريقه اللطيفه اللي نقدر نعرض بيها الكلام ده هي اننا نستخدم حاجه زي Grafana

بس خلينا الاول نشوف احنا زودنا ايه في الكود علشان نلم الاحصائيات في الصوره الي شوفناها من جرافانا بعد ما خلصنا - ركز مع ⬅️ -

```go

    func (d *Dispatcher) Run() {
        for i := 0; i < d.maxWorkers; i++ {
            
            // increase the number of running workers
            RunningWorkers.WithLabelValues("Emails").Inc() ⬅️⬅️⬅️⬅️⬅️⬅️⬅️⬅️

            worker := NewWorker(d.WorkerPool)
            worker.Start()
            d.Workers = append(d.Workers, worker)
        }

        go d.dispatch()
    }

```

```go

    func (d *Dispatcher) dispatch() {
        for {
            select {
            case job := <-JobQueue:
                
                // Increase running jobs Gauge
                RunningJobs.WithLabelValues("Emails").Inc() ️⬅️⬅️⬅️⬅️⬅️⬅️⬅️

                go func(job Queuable) {
                    jobChannel := <-d.WorkerPool
                    jobChannel <- job
                }(job)
            }
        }
    }

```

```go

    func (w Worker) Start() {
        go func() {
            for {
                w.WorkerPool <- w.JobChannel

                select {
                case job := <-w.JobChannel:
                    startTime := time.Now()

                    // track the total number of jobs processed by the worker
                    JobsProcessed.WithLabelValues(w.Name, "Emails").Inc() ️⬅️⬅️⬅️⬅️⬅️⬅️⬅️
                    if err := job.Handle(); err != nil {
                        log.Fatal("Error in job: %s", err.Error())
                    }
                    // Decrease the number of running jobs once we finish
                    RunningJobs.WithLabelValues("Emails").Dec() ️⬅️⬅️⬅️⬅️⬅️⬅️⬅️
                    
                    // ⬇️ Register the proccesing time in the Histogram ⬇️
                    ProcessingTime.WithLabelValues(w.Name, "Emails").Observe(time.Now().Sub(startTime).Seconds()) ️⬅️⬅️⬅️⬅️⬅️⬅️⬅️
                }
            }
        }()
    }

```

اتمني ان الكود كان واضح فوق احنا زودنا فيه ايه علشان نلم الاحصائيات

نفتح جرافانا و نشتغل بقي


- اول حاجه محتاجين نضيف Promethues من ال DataSource

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/granfa-add-prometheus.png)


- نبدا نضيف Dashboard

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/grafana-add-dashobard.png)


- نضيف اول حاجه ال Singlestat علشان ال counters / gauge

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/add-singleslat.png)



- الخطوه الاولي نختار برومثيوس كداتا سورس، بعدين رقم ٢ ندور علي الميترك ولما نختارها هتتنقل لرقم ٣ لوحدها

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/define-singlestat-metric.png)


- نختار من options tab ان الرقم يكون current او total علي حسب الاحصائيه. في حالتنا هو current

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/options-current.png)



- ومن ال General نكتب اسم ال metric

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/general-title.png)



- بعدين نتحكم في مقاسها من ال + و ال - 

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/panel-size.png)


هنعمل كمان واحده لل  RunningWorkers بنفس الطريقه والاختلاف هيكون ان اسم الميترك worker_workers_running

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/2panels.png)


- نعمل كمان جراف لطيف نعرف فيه احنا بنستقبل كام job في الدقيقه, واسم الميتريك worker_jobs_running

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/2panels-w-graph.png)


لو بعتنالها دلوقتي شويه ريكوستات هتظهر فيها بيانات بشكل لطيف بس اهم حاجه نشغل ال auto refresh

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/grafana-refresh.png)



![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/graph-running.png)

و نختمها باخر جراف اللي بيعرفنا ال processing time قد ايه  بس محتاجين نعرف ان القيمه بتاعته بالمللي ثانيه لان ده processing time
بس ده الميترك هتبقي المجموع ع العدد

worker_jobs_process_time_seconds_sum / worker_jobs_process_time_seconds_count

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/duration-metric.png)

    

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/define-unit.png)


و ف الاخر بقي عندنا داشبورد نقدر نعرف منها ال channels شغاله ازاي و نجاوب علي اسئله زي

- هل فيه running jobs كتير و مش بتخلص بسرعه
- هل فيه وقت معين بنستقبل فيه jobs كتير عن باقي اليوم ، طب ايه السبب  ؟
- هل ال process duration بقي اكتر من الاول ، طيب هل الزياده مقبوله ولا فيه حاجه غلط ؟
- هل الworkers شغاله تمام ولا فيها مشاكل

و النتيجه النهائيه عملي :D 

![Go-Channels-and-Montiroing-Grafana](/images/article/go-channels/final.gif)


## الخاتمه

المقاله كانت طويله شويه للاسف :D لكن عرفنا منها 

- ازاي نعمل Channles
- ازاي نطبق ع الDispatcher & Workers
- نتحكم في ال Workers ازاي
- ازاي نسجل الاحصائيات و نعرضها بشكل سهل لاي حد يفهمه
- نقدر نتوقع اي مشكله بتحصل في السيستم و ف انهي جزء بالظبط

حاجات ناقصه كان المفروض نظبطها

- مفيش طريقه بنتعامل بيها مع اي Job بترجع مشكله، ممكن علي حسب نوع المشكله يا نبعتها لل Queue تاني ، يا نعملها Log
- مفيش Data Persistence ف لو حصل اننا عملنا restart كل ده هيضيع :D 
- موضحناش ازاي ممكن نستخدم اي messages system زي Kafaka , RabbitMQ, Redis و نستخدمها مع ال channels لل Qeueu
- اشياء اخري عبثيه :D

و فالنهايه الكلام ده طبقته علي بروجكت صغير و علي Docker ف تقدر تسخدمه وتتفرج عليه بسهوله من اللينك ده

[https://github.com/ahmedash95/go-channels-demo](https://github.com/ahmedash95/go-channels-demo)


## المصادر:
- [Handling 1 Million Requests per Minute with Golang](https://medium.com/smsjunk/handling-1-million-requests-per-minute-with-golang-f70ac505fcaa)
- [Monitoring Go Applications With Prometheus](https://scot.coffee/2018/12/monitoring-go-applications-with-prometheus/)

واخيرا لو لقيت اي خطا ف الكلام ده اتمني لو توضحه ف كومنت علشان نصلحه و شكرا :) 

{{< rtl/end >}}