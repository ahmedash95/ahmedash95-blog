---
title: "Twitter @ShareAsPic app with Go & Chromedp"
date: 2019-10-16
lang: AR
---
{{< rtl/start >}}
العادي ان كل فتره بلاقي تويته عجباني ليها علاقه بشغلي اني بصورها و انزلها ع الفيسبوك عندي او اي جروب انا شايف ان التويته ممكن تكون مفيده فيه. ف استخدمت بعض الادوات المتاحه اللي ساعدتني في اقل من ٢٠ ساعه اني اخلص التطبيق بالشكل اللي انا شايفه مناسب للغرض اللي انا عاوزه او بما معناه MVP و مش تطبيق scalable. ف حابب اني اشارك انا عملتها ازاي واتمني الموضوع يكون مفيد ليك. - عزيزي القارئ -

قبل اي حاجه اتفضل السورس كود للكلام ده كله وتوضيح ان ده مجرد MVP هدفه الوحيد انه مثال ازاي ممكن تستخدم chromeDP 
{{< ltr/start >}}
[https://github.com/ahmedash95/shareAsPic](https://github.com/ahmedash95/shareAsPic)
{{< ltr/end >}}

في الاول هوضح الادوات اللي انا استخدمتها و تعريف بسيط بيها

- **لغه GoLang**: انت ممكن تستخدم اي لغه من اللغات المعروفه ولكن انا فضلت Go لاني عاوز اتعمق فيها و اكتسب فيها خبره اكتر ف اي وقت متاح. ده غير بساطه و سهوله اللغه اللي بتنجز في الشغل اكتر من الكتابه باي لغه تانيه

- **Golang Twitter API**: دي مكتبه هتساعدنا نستخدم Twitter Stream API اللي هتبعتلنا الغريدات - Tweets - اللي الناس بتكتبها و هنفلترها بكلمه معينه بدل ما نعمل احنا الفلتر بايدينا و هتعرف ازاي لما تكمل قراءه المقاله

- **Twitter Stream API**: بكل بساطه StreamAPI يعني ايه: نقدر نقول معناها ان فيه سيرفر بنتصل بيه علي بروتوكول معين مش HTTP و بنقول للبروتوكول ده خليني قاعد معاك و اي بيانات تجيلك قولي عليها. وده لانه بيدعم الاتصال المفتوح ف اي سيرفر يقدر تصل بيه علي البروتوكول و يفضلو مع بعض اي بيانات بتيجي بيبعتها للسيرفرات اللي قاعده معاه دي.
والميزه الاضافيه ان تويتر بيدعم شويه خيارات للفلتره ف تقدر تقوله هاتلي اي تغريده من اليوزر الفلاني، او اي تغريده فيها كلمه مصر - ام الدنيا - قد الدنيا

- **Chromedp - Chrome DevTools Protocol**: وده بروتوكول في جوجل كروم بيسمحلك تتعامل مع البراوز من خلال شويه اوامر او كود و بيندرج تحتهم ال inspect element و ال network and source tab اللي بسنتخدمهم بشكل يومي في جوجل كروم. بس هنا هنستخدمه علشان نفتح تويتر و ناخد صوره من التويته - screenshot - و نعملها شير مع المتسخدم


- **Redis (InMemory DB):** بستخدم ريدس لاني مش حابب اعمل سكرين شوت و ارد علي نفس التويته مرتين، فلو اي شخص عمل share this علي نفس التويته اكتر من مره ، هيرد عليه ف اول مره بس 

![App Diagram](/images/article/go-twitter-chromedp/diagram.png)

## كيف يعمل:
كل رقم بالاسفل يعبر عن الصوره بالاعلي

1 - كعاده شبكات التواصل الاجتماعي كل يوم الاف من الناس بتكتب تغريدات يوميا، و تخزين بعض التغريدات و تحليلها قد ياتي بالنفع لصالح شركه ، او حكوميه او حتي من باب اللعب زي ما انا بعمل دلوقتي 

2 - الخطوه التانيه من دوره الحياه اللي بيعتمد عليها التطبيق ان التغريدات دي لما يستقبلها سيرفر تويتر، بتبدا رحلتها ف كذا نظام معقد جدا و كل نظام ليه مهمه محدده بينفذها ولازم ينفذها علي اكمل وجه


3 - . منها ال StreamingAPI اللي بدورها بعتمد عليها اني استقبل التغريدات. ولكن نقطه لازم ناخد بالنا منها و هي انه مش صحيح انك تسمع لكل التغريدات اللي بتيجي لتويتر علشان تاخد منهم ١٠٠ تويته او حتي ١٠ الاف. 

ف تويتر بتوفر بعض الفلاتر اللي استخدامها هيوفر علينا و علي التطبيق شويه و هي اني ممكن اقوله هات التغريدات اللي فيها  كلمه معينه زي @ShareAsPic بحيث ان لما التطبيق يستلم حاجه من تويتر ف هي متوقعه بالنسبالنا ان فيه شخص عمل منشن للتطبيق في تغريده

{{< gist ahmedash95 b58da9f387134446a51ad8089b725a56 >}}

4 - من هنا تبدا الحياه داخل التطبيق. ف عند استلام اي تغريده بنستقبل منها شويه بيانات تويتر بيبعتها زي مين الشخص اللي عمل منشن و بما انه عمل منشن ف ريبلاي ف احنا بنشوف هو عمل ريبلاي علي مين 

{{< gist ahmedash95 7721e768a9538026b7e5fdb6ca20cf41 >}}

ف بنبعت ال InReplyToScreenName و ال InReplyToStatusID ل chromedp علشان يفتح المتصفح و ياخد سكرين شوت


5 - هنا تظهر فائده ال Headless Browser او ال Chromedp ف هو بيحاكي عمليه فتح رابط - في حالتنا - زي  "https://twitter.com/{UserName}/status/{TweetID}" . ف يفتحها المتصفح و باستخدام احدي خصائص chromedp  ياخد سكرين شوت (screenshot) من ال HTML Element الذي يحتوي التغريده فقط 

![ChromeDP-HTML-Element](/images/article/go-twitter-chromedp/chromedp-html-element.png)


{{< gist ahmedash95 1ca41a5add4b3446867bdfbd9041c671 >}}

6 - بعد كدا بنستخدم Twitter API علشان نرد بالصوره 

{{< gist ahmedash95 158af62f5e9f99a001b5b141d66006d1 >}}

و النتيجه النهائيه

![Final-Results](/images/article/go-twitter-chromedp/final.png)


# الخاتمه

طبعاً التطبيق ده مفيش منه اي هدف غير انه مجرب تجربه بسيطه ف ازاي استخدم  chromedp ونتعامل بطريقه browser interactions as code. طبعا الشركات بتسخدمه ف حاجه زي ال end2end testing او web scrapers خصوصا مع  Single Page Applications. ولكن فيه ناس تانيه بتستخدمه علشان ت automate حاجات ف حياتها زي شخص استخدمها علشان يدفع الاشتراك الشهري ف خدمه مفيهاش automatic subscription renwal ف كان لازم كل شهر يفتكر و يدخل يدفع بنفسه. 

ف النهايه قد اصيب و اخطا و قد تجد بعض الاخطاء.  ف اذا وجد خطا يا ريت تتكرم و توضحه ف كومنت
