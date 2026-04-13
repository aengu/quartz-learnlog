# Two Scoops of Django

Status: In progress

책을 읽으면서 도움되는 내용을 정리하고 있습니다.

- 명시적 성격의 상대 임포트 이용하기
    - 파이썬에서는 명시적 성격의 상대 임포트를 통해 모듈의 패키지를 하드 코딩하거나 구조적으로 종속된 모듈을 어렵게 분리해야 하는 경우들을 피해갈 수 있다.
    
    ```python
    # do not!: 만약 cones의 이름을 변경하려고 한다면, 일일히 다 변경해야 한다 끔찍
    from cones.models import WaffleCone
    from cones.forms import WaffleConeForm
    from core.views import FoodMixin
    
    # do this: 참고로 .도 떼어도 문제 없지만 .를 붙이는게 좋다고 한다
    from .models import WaffleCone
    from .forms import WaffleConeForm
    from core.views import FoodMixin
    ```
    

- import * 는 절대 쓰지 말자: 라이브러리끼리 충돌할 수 있으니 절대 쓰지말자..
    
    ```python
    from django.forms import CharField
    from django.db.models import CharField
    ```
    
- 단일 객체에서는 get보단 get_object_or_404()를 이용하자
    - try-except블록으로 예외 처리할 필요 x
    - get 사용 시 exception들
        - ObjectDoesNotExist, DoesNotExist, MultipleObjectsReturned

- 쿼리를 좀 더 명확하게 하기 위해 지연 연산 이용하기
    
    ```python
    def fun_function(**kwargs):
    	return Promo.objects.active().filter(Q(name__starswith=name) |
    				 Q(description__icontains=name))
    ```
    
    ```python
    def fun_function(**kwargs):
    	results = Promo.objtcs.active()
    	results = results.filter(
    					Q(name__starswith=name) |
    				 Q(description__icontains=name)
    					)
    	return results
    ```
    
- 쿼리 표현식 사용
    - 아이스크림 상점을 방문한 모든 고객 중 한 번 방문할 때마다 평균 한 주걱 이상의 아이스크림을 주문한 모든 고객 목록을 가져오는 샘플을 작성해 보자
    
    ```python
    customers = []
    
    for customer in Customer.objtects.iterate():
    	if customer.scoops_ordered > customer.store_visits:
    		stomer.append(customer)
    ```
    
    아주 별로다. 모든 고객 레코드에 대해 하나하나 파이썬을 이용한 루프가 돌고 있다. 매우 느리며 메모리도 많이 사용하게 된다.
    
    또한 코드가 얼마나 이용되는지에 상관없이, 코드 자체가 경합 상황 (race condition 공유 자원에 대해 여러 개의 프로세스가 동시에 접근을 시도하는 상태)에 직면하게 된다. 여기서 단순 read 역할만을 하는 상황에서는 문제가 없을지 몰라도, 실행 중에 update가 처리되는 환경에서라면 데이터 분실이 생길 여지가 있다.
    
    ```python
    
    from django.db.models import F
    Customer.objtects.filter(scoops_ordered__gt = F('store_visits'))
    ```
    
    ```sql
    select * from customers_customer where scoops_ordered > store_visits
    ```
    
    쿼리 표현식을 사용함으로써 프로젝트의 안정성과 성능을 향상시킬 수 있다.
    
    - FBV, CBV
        - 범용적인 클래스 기반 뷰들의 구조 중 하나가 이미 떠올랐는가?
        - 속성 오버라이딩 만으로 클래스 기반 뷰가 가능 하겠는가?
        
        - 다른 뷰를 생성하기 위해 서브 클래스를 만들어야 하는가?
        - 클래스 기반 뷰로 구현하기 위해 장고 소스 코드 까지 들여다볼 정도로 난해한가?
        - 클래스 기반 뷰로 처리할 경우 극단적으로 복잡해지겠는가? (예: 뷰가 한개 이상의 폼을 처리하는가?)
    
    - CBV
        
        ```python
        from django.conf.urls import url
        from django.views.generic import DetailView
        
        from tasting.models import Tasting
        
        # do not this
        urlPatterns = [
        	url('', DetailView.as_view(models = Tasting, template_name = ''), name = '')
        	
        ]
        ```
        
        당연히 재사용이 힘들다. 아주 별로다
        
        ```python
        class TasteListView(ListView):
        	model = Tasting
        class TastingDetailView(DetailView):
        	model = Tasting
        class TastringResultView(TastingDetailView):
        	template_name = ''
        
        url(view = views.TastieListView.as_view(), name='list')
        
        ```
        

- rest api
    - django에서 패키지 api를 제작하기 위한 패키지들
        - django-rest-framework: cbv를 바탕으로 브라우징이 가능한 편리한 api 기능 등을 제공한다.(fbv도 가능한 것 같음) 가장 많이 쓰이는 방법
        - django-tastypie
        - django-braces(클래스 기반 뷰), django-jsonview(함수 기반 뷰): 빠르고 간편하게 개발하기 쉬움
    - 기본 rest api 디자인의 핵심
        
        [http 메서드](Two%20Scoops%20of%20Django/http%20%EB%A9%94%EC%84%9C%EB%93%9C%204c774cf8761b4bc2a4818fa6b378682b.csv)
        
        [HTTP response status codes - HTTP | MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
        
    
    - api용 앱을 분리하는게 좋다
        - serializer, renderer, 뷰를 따로 빼서 앱으로 만들고 이 앱의 이름에 해당 api 버전을 포함해야 한다
        - api의 url에 버전 정보를 나타내는 것은 매우 유용하다. 예를 들면 /api/v1/flavors 또는 /api/v1/users 식으로. → api기 변경될 때마다 기존 이용자들은 이전 버전으로 api를 호출함으로써 기존 구성에 급작스러운 문제를 일으키지 않을 수 있는 장점이 있다. 또한 기존 api 사용자들을 고려하여 api버전을 업그레이드한 이후에도 현재 api와 이전 버전의 api를 둘 다 유지하는 것이 매우 중요하다. 사용을 중지하기로 한 api라도 몇 달간은 이용할 수 있게 해주는 것이 일반적이다.

- 장고 프로젝트 배포하기
    - 다중서버 구조
        - 데이터베이스 서버: postgreSql, Mysql emd
        - wsgi 애플리케이션 서버: 일반적으로 uWsgi나 구니콘에 Nginx를 연동하거나 아파치와 mod_wsgi를 이용한다
        
        추가적으로
        
        - 정적 파일 서버: 자체적으로 구성하고 싶다면 Nginx나 아파치가 정적 파일을 빠르게 서비스 할 수 있다. 하지만 자체적으로 아마존 클라우드프론트 같은 CDN 서비스가 기본 기능을 놓고 볼 때 상대적으로 저렴한 조건을 제시한다.
        - 캐시 또는 비동기 메시지 큐 서버: redis, memcached 또는 varnish를 이용할 수 있다.
    
    이렇게 한 가지 일만 전담하는 전문 서버들을 구성함을써 프로젝트 필요에 따라 각 서버에 대한 변경, 최적화 또는 서버 대수 변경을 할 수 있다.
    
    마지막으로 각 서버에서 프로세스들을 관리해야 하는데 우리는 다음 방법들을 그 순서대로 선호한다
    
    1. supervisord
    2. init 스크립트
    
- 좀 더 발전된 다중 서버 구성
    
    각 타입에 따른 다중 서버를 구성하고 로드밸런싱을 구성한다.
    
    로드밸런서는 하드웨어 또는 소프트웨어 기반으로 구성할 수 있다.
    
    - 소프트웨어 기반: HA 프록시, 바니시, 엔진엑스
    - 하드웨어 기반: 파운드리, 주니퍼, DNS 로드 밸런서
    - 클라우드 기반: 아마존 elb,랙스페이스 클라우드 로드 밸런서
    
    수평 스케일링: 위와 같은 구성, 일반적으로 로드를 처리하기 위해 서버 여러 대를 추가하는 구성. 이런 수평 스케일링을 하기 이전에 각 서버의 하드웨어를 업그레이드하고 랩을 늘리는 수직 스케일링을 먼저 고려해보자.