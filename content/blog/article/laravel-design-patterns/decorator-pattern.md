---
title: "Laravel Design Patterns: Decorator"
date: 2020-02-08
lang: AR
category: ["laravel-design-patterns"]
tags: ["laravel","design-patterns"]
cover: '/images/article/laravel-design-patterns/decorator.png'
---
{{< rtl/start >}}
# الـ Decorator pattern بالعربيه ( المزخرف ). 


### **تعريفه:**

المزخرف وظيفته انه يقوم بإضافة سلوك علي كائن (object) دون التاثير علي الكائنات الاخري من نفس الفئه (class) و سنتعرف علي معني ذلك لاحقاً. 


### تعريف النمط (pattern) علي موقع [ويكيبيدا](https://ar.wikipedia.org/wiki/%D9%86%D9%85%D9%88%D8%B0%D8%AC_%D8%A7%D9%84%D8%AA%D8%B5%D9%85%D9%8A%D9%85_%D8%AF%D9%8A%D9%83%D9%88%D8%B1) هو 

> نموذج التصميم ديكور يهدف إلى توفير وسيلة لربط الحالات الجديدة والسلوك إلى كائن بطريقة ديناميكية. والكائن لا يعلم انه يجري عليه عملية ديكور "Decoration" ، الأمر الذي يجعل هذا النموذج مفيد لتطور النظم. وهناك نقطة رئيسية في تنفيذ هذا النموذج وهو انه يعمل على تزيين ال class الاصلي و حتى المورث منه على حد سواء.


اهم شئ في هذا التعريف هو ان الكائن (object) لا يعلم اي شئ بخصوص الزخرفه او السلوك الإضافي الذي تم إضافته عليه

### **كيف يستخدم وما المشكله التي يقوم بحلها:**

لنفترض اننا نريد ان نقوم بعمل تخزين مؤقت (caching) لبعض البيانات في التطبيق بدلا من الاتصال بقاعدة البيانات في كل مره نحتاج فيها هذه البيانات

ف مثلا لدينا هنا Post Model

```php
<?php

class Post extends Model
{
    public function scopePublished($query) {
    	return $query->where('published_at', '<=', 'NOW()');
    }
}
```

وفي الكنترولر لدينا الـindex method
```php
<?php

class PostsController extends Controller
{
    public function index() {
    	$posts = Post::published()->get();
    	return $posts;
    }
}
```

لنقوم بعمل تخزين مؤقت (caching) يوجد عدة طرق من اشهرها المثال التالي 

```php
<?php

class PostsController extends Controller
{
    public function index() {
    	$minutes = 1440; # 1 day
    	$posts = Cache::remember('posts', $minutes, function () {
    		return Post::published()->get();
		});
    	return $posts;
    }
}
```

الآن لدينا تخزين مؤقت لمدة يوم و لا نحتاج ان نقوم باستدعاء قاعدة البيانات في كل مره نحتاج فيها الـPosts
ولكن المشكله هنا ان الـ controller يفعل اشياء كثيرة. فهو يعلم كيف يقوم بعمل التخزين المؤقت و اذا لم يكن هناك تخزين مؤقت فهو يعلم ايضا كيف يستدعيها من قاعده البيانات و يقوم بتخزينها مره اخري. 

ايضا في كل مره نحتاج ان نقوم بعمل تخزين مؤقت حول المقالات سنجد انفسنا نكرر الكثير من الكود. ف تخيل مثل هذه الطريقه وانت لديك Posts, Comments, Categories and Tags سيكون الـcontroller ممتلئ باشياء كثيره و سيكون من الصعب فهمه عند تطويره. ايضا هو غير قابل للاختبار (Non Testable) و ايضا قد اهملنا مبدا ال Single Responsibility حيث ان الـClass يفعل اشياء كثيره. 

لذلك سننتقل اولاً الي الـRepository pattern لنفصل بين كيف نجلب ال Posts  و كيف يستخدمها الكنترولر

اول خطوه نقوم بانشاء ملف في المسار التالي app/Repositories/Posts/PostsRepositoryInterface.php

و يكون المحتوي كالتلي 
```php
<?php

namespace App\Repositories\Posts;

interface PostsRepositoryInterface 
{
	
	public function get();

	public function find(int $id);

}
```

هنا نحن نعلم ان Posts Repository وظيفته ان يقوم بجلب المقالات او ايجاد مقال معين عن طريق الـ **ID**

لنقوم بإنشاء الـ PostsRepository في نفس المسار

```php
<?php

namespace App\Repositories\Posts;

use App\Post;

class PostsRepository implements PostsRepositoryInterface
{
	protected $model;

	public function __construct(Post $model) {
		$this->model = $model;
	}
	
	public function get() {
		return $this->model->published()->get();
	}

	public function find(int $id) {
		return $this->model->published()->find($id);
	}

}
```

نلاحظ ان الكود يسهل جدا فهمه و ايضا يطبق مبدا ال Single Responsilbility حيث ان وظيفته الاولي و الاخيره هي فقط التعامل مع الـPosts. ايضا نستفيد هنا من الـautowiring في Laravel حيث ان الـIOC container يعلم ان هذا الـClass يحتاج Post Model و سيقوم بإرساله تلقائيا عند استخدامه كما سنفعل في الController تالياً

في PostsController سنقوم بتغيير الكود كالآتي

```php
<?php

namespace App\Http\Controllers;

use App\Repositories\Posts\PostsRepositoryInterface;
use Illuminate\Http\Request;

class PostsController extends Controller
{
    public function index(PostsRepositoryInterface $postsRepo) {
    	return $postsRepo->get();
    }
}
```

اصبح من السهل جداً الآن قراءة و فهم ما يفعله الcontroller حيث انه يقوم بإستدعاء الRepository ليجلب المقالات Posts دون معرفه التفاصيل التي لا يحتاج لها مثل كيف يتم استدعاء البيانات، هل هي من قاعدة البيانات ام من التخزين المؤقت ام هي من خدمه خارجيه (third party service) مثل API او غير ذلك

لكن الآن يوجد مشكله واحده ان هذا الكود لن يعمل حيث ان دالة index تحتاج كائن **PostsRepositoryInterface** و نحن نعلم ان الInterface لا يمكن استخدامه ككائن حيث انه لا يوجد به كود وهو غير مصمم لذلك. 

في هذه الخطوه ينبغي علينا ان نفهم Laravel انه عندما يتم استدعاء الـPostsRepositoryInterface ان يقوم بإرسال كائن ال PostsRepository وليس ال Interface . وهذه من مميزات الـIOC Container و ال Depedency Injection و سنعرف اكثر لما فيما بعد ولكن الآن دعنا نقوم بتنفيذ ما قلناه في ال app\Providers\AppServiceProvider.php

```php
<?php

namespace App\Providers;

use App\Repositories\Posts\PostsRepositoryInterface;
use App\Repositories\Posts\PostsRepository;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->bind(PostsRepositoryInterface::class,PostsRepository::class);
    }
}
```

كما نري في دالة register() قمنا بعمل ربط بين الـInterface و الكائن المربوط به. فعندما نسال لارافيل في اي وقت سواء في constructor او داله في الcontroller او باستخدام app(PostsRepositoryInterface::class) سيقوم لارافيل بفهم اننا هنا نسال عن كائن من نوع ال PostsRepository 

الآن إذا قمنا بتجربه الكود سنجد انه يعمل دون اي مشاكل و يسهل جدا فهم الكود يحث انه لايوجد اي جزء معقد او اي داله تقوم بعمل اشياء معقده غير مترابطه.

الآن ناتي لمرحله التخزين المؤقت و كيف نطبق نمط الزخرفه (Decorator Pattern) لتنفيذ هذا.

لاحظ اننا قلنا سابقاً ان نمط الزخرفه وظيفته انه يقوم بإضافة سلوك علي كائن دون ان يعلم الكائن بنفسه ذلك. و سنفهم المقصود بذلك الآن

لنقم بإنشاء Repository جديد و نسميه PostsCacheRepository في نفس المسار app/Repositories/Posts/PostsCacheRepository.php و سيكون محتواه كالإتي

```php
<?php

namespace App\Repositories\Posts;

use App\Post;
use Illuminate\Cache\CacheManager;

class PostsCacheRepository implements PostsRepositoryInterface
{
	protected $repo;

	protected $cache;

	const TTL = 1440; # 1 day

	public function __construct(CacheManager $cache, PostsRepository $repo) {
		$this->repo = $repo;
		$this->cache = $cache;
	}
	
	public function get() {
		return $this->cache->remember('posts', self::TTL, function () {
			return $this->repo->get();
		});
	}

	public function find(int $id) {
		return $this->cache->remember('posts.'.$id, self::TTL, function () {
			return $this->repo->find($id);
		});
	}
}
```

سنجد هنا ان PostsCacheRepository يستخدم ال PostsRepository وال Cache لتنفيذ السلوك المطلوب. و ايضا يستخدم نفس  الـPostsRepositoryInterface. فهنا السلوك هو الcache الذي تم تطبيقه علي كائن PostsRepository و هذا الكائن لا يعلم بوجود السلوك Caching. 

و باستخدام نفس النمط Decorator يسهل علينا فيما بعد اضافة اي سلوك اخر. مثلا اذا كان لدينا خدمه منفصله تدعي Posts Service و نريد ان نقوم باستخدم الـ HTTP API لنستدعي الposts و اذا لم نجده في هذه الخدمه نقوم باستدعائه من قاعده البيانات لدينا. بالطبع من السهل تنفيذ هذا حيث اننا سنقوم بإنشاء Repository جديد باسم PostsApiRepository و نفعل مثل ما فعلنا في ال PostsCacheRepository.

الان ما زال الـPostsController يستخدم ال PostsRepository و لا يعلم بوجود الPostsCacheRepository  بعد و لتنفيذ ذلك بكل سهوله سنقوم بالتغير في ال AppServiceProvider و نقوم بعمل ربط (binding) للـPostsCacheRepository كالآتي

```php
<?php

namespace App\Providers;

use App\Repositories\Posts\PostsRepositoryInterface;
use App\Repositories\Posts\PostsCacheRepository;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->bind(PostsRepositoryInterface::class,PostsCacheRepository::class);
    }
}
```

والان التطبيق بالكامل يعلم انه عند استدعاء الposts سنستخدم الـPostsRepositoryInterface و لارافيل سيرسل الكائن المناسب و من السهل علينا فيما بعد تغيير نوع هذا الكائن في اي وقت و سيتطلب التغيير مكان واحد فقط و هو ال AppServiceProvider.


### الخاتمه 
وبهذا نكون انتهينا من فهم و تطبيق ال Decorator Pattern و فهمنا ما المشكله التي يقوم بحلها و هكذا يمكننا تطبيقه في اي وقت نريد ان نقوم فيه بإضافه سلوك علي كائن معين. و هذا النمط يساعدنا في فصل و اضافه اي سلوك دون الحاجه للتعديل في الكائن نفسه و دون حاجه الكائن لمعرفه اي سلوك اضافه يحدث له و انه يمكن تغيره في اي وقت دون الحاجه الي التعديل في كود الكائن نفسه و الوظائف التي يفعلها.


{{< rtl/end >}}