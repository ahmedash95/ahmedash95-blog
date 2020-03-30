---
title: "Laravel Design Patterns: Facade"
date: 2020-03-02
lang: AR
category: ["laravel-design-patterns"]
tags: ["laravel","design-patterns"]
cover: '/images/article/laravel-design-patterns/facade.png'
---

{{< rtl/start >}}
# الـFacade pattern بالعربيه (المزيف)

### **تعريفه:**

المزيف وظيفته انه يقوم بإخفاء التفاصيل المعقده لـclass معين دون الحاجه الي إظهار اي تفاصيل دقيقه عن الـClass الذي يقوم بتزييفه

### تعريف النمط علي [ ويكيبيديا](https://en.wikipedia.org/wiki/Facade_pattern):

{{< ltr/start >}}
> The facade pattern (also spelled façade) is a software-design pattern commonly used in object-oriented programming. Analogous to a facade in architecture, a facade is an object that serves as a front-facing interface masking more complex underlying or structural code. A facade can:

{{<ltr/end >}}


### **كيف يستخدم و ما المشاكل التي يقوم بحلها:**

يمكنك هذا النمط (pattern) من اخفاء التفاصيل التي تحتاجها كل مره تقوم فيها باستخدام class معين. ف علي سبيل المثال إذا فرضنا ان لدينا مدونه و نريد مع كل تدوينه ننشرها ان نغرد علي تويتر برابط هذه التدوينه.

اولاً سنحتاج مكتبه [dg/twitter-php](https://github.com/dg/twitter-php) لارسال التغريدات الي تويتر. و اذا نظرنا الي ال README سنجد ان الخطوات المطلوبه لكتابه تغريده بسيطه هي 

```php
<?php

use DG\Twitter\Twitter;

$twitter = new Twitter($consumerKey, $consumerSecret, $accessToken, $accessTokenSecret);

$twitter->send('I am fine today.');
```

لاحظ اننا نحتاج بعض البيانات السريه مع كل كائن حتي نستطيع ارسال التغريده ف لدينا (consumerKey, consumerSecret, accessToken, accessToken Secret). 

لاحظ هنا اننا لا نحتاج اي Factory حيث انه لا يوجد لدينا الا class Twitter الذي نحتاجه في كل مره نحتاج ان نرسل تغريده جديدة.

يمكننا تطبيق نمط المزيف Facade Pattern بكل سهوله كما بالشكل التالي 


```php
<?php

class TwitterFacade 
{
  public static function get()
  {
    return new Twitter($consumerKey, $consumerSecret, $accessToken, $accessTokenSecret);
  }
}
```

لاحظ اننا نحتاج ارسال البيانات مع كل كائن من Twitter class، حيث اننا نقوم بالتطبيق علي Laravel ف يمكننا استخدام ال config كما بالشكل التالي 

في ملف config/services.php قم باضافه twitter كما بالتالي:

```php
<?php

'twitter' => [
    'api_key' => env('TWITTER_API_KEY'),
    'api_secret' => env('TWITTER_API_SECRET'),
    'api_token' => env('TWITTER_Access_TOKEN'),
    'api_token_secret' => env('TWITTER_Access_TOKEN_SECRET'),
],
```

و في TwitterFacade يمكننا تغيير الكود كما بالشكل التالي:

```php
<?php

class TwitterFacade 
{
  public static function get()
  {
      $config = config('services.twitter');
      return new Twitter($config['api_key'], $config['api_secret'], $config['api_token'], $config['api_token_secret']);
  }
}
```

و الآن يمكننا ارسال تغريدات في اي وقت باستخدام الـTwitter Facade كما بالمثال التالي

```php
<?php

TwitterFacade::get()->send('Test tweet from a facade class');
```


اصبح الآن من السهل ارسال التغريدات ولا نحتاج ان نعرف كيف يعمل ال Class كي يرسلها و ما هي البيانات التي يحتاجها. فقط send() method تكفي لارسال تغريده.


### تطبيقها مع Laravel:

لارافيل يدعم الـ Facade بشكل كبير حيث ان اغلب الclasses متوفره ك Facade. و ستجد اغلبهم في config/app.php تحت aliases

```php
<?php

'aliases' => [

    'App' => Illuminate\Support\Facades\App::class,
    'Arr' => Illuminate\Support\Arr::class,
    'Artisan' => Illuminate\Support\Facades\Artisan::class,
    'Auth' => Illuminate\Support\Facades\Auth::class,
    'Blade' => Illuminate\Support\Facades\Blade::class,
    'Broadcast' => Illuminate\Support\Facades\Broadcast::class,
    'Bus' => Illuminate\Support\Facades\Bus::class,
    'Cache' => Illuminate\Support\Facades\Cache::class,
    'Config' => Illuminate\Support\Facades\Config::class,
    'Cookie' => Illuminate\Support\Facades\Cookie::class,
    'Crypt' => Illuminate\Support\Facades\Crypt::class,
    'DB' => Illuminate\Support\Facades\DB::class,
    'Eloquent' => Illuminate\Database\Eloquent\Model::class,
    'Event' => Illuminate\Support\Facades\Event::class,
    'File' => Illuminate\Support\Facades\File::class,
    'Gate' => Illuminate\Support\Facades\Gate::class,
    'Hash' => Illuminate\Support\Facades\Hash::class,
    'Lang' => Illuminate\Support\Facades\Lang::class,
    'Log' => Illuminate\Support\Facades\Log::class,
    'Mail' => Illuminate\Support\Facades\Mail::class,
    'Notification' => Illuminate\Support\Facades\Notification::class,
    'Password' => Illuminate\Support\Facades\Password::class,
    'Queue' => Illuminate\Support\Facades\Queue::class,
    'Redirect' => Illuminate\Support\Facades\Redirect::class,
    'Redis' => Illuminate\Support\Facades\Redis::class,
    'Request' => Illuminate\Support\Facades\Request::class,
    'Response' => Illuminate\Support\Facades\Response::class,
    'Route' => Illuminate\Support\Facades\Route::class,
    'Schema' => Illuminate\Support\Facades\Schema::class,
    'Session' => Illuminate\Support\Facades\Session::class,
    'Storage' => Illuminate\Support\Facades\Storage::class,
    'Str' => Illuminate\Support\Str::class,
    'URL' => Illuminate\Support\Facades\URL::class,
    'Validator' => Illuminate\Support\Facades\Validator::class,
    'View' => Illuminate\Support\Facades\View::class,

],
```

لنقم بإنشاء ملف جديد باسم TwitterFacade.php في المسار App\Facades\TwitterFacade.php و نضح المحتوي التالي:

```php
<?php

namespace App\Facades;

use Illuminate\Support\Facades\Facade;

class TwitterFacade extends Facade {
    protected static function getFacadeAccessor()
    {
        return 'twitter-poster';
    }
}
```

لاحظ انه يقوم باستخدام كلاس Facade الذي يوفره لارافيل و يستخدم getFacadeAccessor كي يقوم بارجاع ال Object و الاسم المعرف هنا twitter-poster (لاحظ انه يمكن ان يكون اي اسم تريد)

و الآن في ال App\Providers\AppServiceProdvider.php قم بوضع الكود التالي في ال register method 

```php
<?php

public function register()
{
    $this->app->bind('twitter-poster',function(){
        $config = config('services.twitter');
        return new Twitter($config['api_key'], $config['api_secret'], $config['api_token'], $config['api_token_secret']);
    });
}
```


لاحظ اننا في ال AppServiceProvider استخدمنا twitter-poster كمعرف يقوم بارجاع ال twitter object و منها يمكن لل Twitter facade ان يستخدمه

الآن يمكننا استخدامه بالشكل التالي


```php
<?php

Route::get('/tweet',function(){
    \App\Facades\TwitterFacade::send('Hello from ahmedash.com: Facade design pattern article');
});
```
و النتيجه هي

![tweeted](/images/image-1583174686394.png)

# الخاتمه

وبهذا نكون انتهينا من فهم و تطبيق الـ Facade pattern و فهمنا متي يمكن استخدامه (لاخفاء اي تعقيدات عن المستخدم دون الحاجه لمعرفه التفاصيل في كيف يعمل هذا الـClass) و ايضاً عرفنا كيف يعمل و كيف يمكن استخدامه مع لارافيل 