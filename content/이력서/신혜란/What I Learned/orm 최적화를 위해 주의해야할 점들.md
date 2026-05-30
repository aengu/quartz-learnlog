---
title: "orm 최적화를 위해 주의해야할 점들"
---

# orm 최적화를 위해 주의해야할 점들

Status: In progress

- **N+1 Ploblem**
    
    ```python
    class UserInfo(models.Model):
        tel_num = models.CharField(max_length=128, null=True)
    
    class User(AbstractUser):
        userinfo = models.OneToOneField('orm_practice_app.UserInfo', on_delete=models.CASCADE, null=False) 
    ```
    
    위와 같은 구조일 때, User를 통해서 대응하는 UserInfo를 확인한다면 다음과 같이 작성할 수 있다.
    
    1. User를 가져오고, 순회하며 대응하는 userInfo를 출력하는 경우
        
        ```python
        >>> a = User.objects.filter(id__lte=30)
        
        >>> for aa in a:
        ...     aa.userinfo
        ... 
        
        SELECT "orm_practice_app_user"."id",
               "orm_practice_app_user"."password",
          FROM "orm_practice_app_user"
         WHERE "orm_practice_app_user"."id" <= 30
        Execution time: 0.008426s [Database: default]
        
        SELECT "orm_practice_app_userinfo"."id",
               "orm_practice_app_userinfo"."tel_num"
          FROM "orm_practice_app_userinfo"
         WHERE "orm_practice_app_userinfo"."id" = 1
         LIMIT 21
        Execution time: 0.005598s [Database: default]
        <UserInfo: UserInfo object (1)>
        
        SELECT "orm_practice_app_userinfo"."id",
               "orm_practice_app_userinfo"."tel_num"
          FROM "orm_practice_app_userinfo"
         WHERE "orm_practice_app_userinfo"."id" = 2
         LIMIT 21
        Execution time: 0.004125s [Database: default]
        <UserInfo: UserInfo object (2)>
        ......
        
        SELECT "orm_practice_app_userinfo"."id",
               "orm_practice_app_userinfo"."tel_num"
          FROM "orm_practice_app_userinfo"
         WHERE "orm_practice_app_userinfo"."id" = 30
         LIMIT 21
        Execution time: 0.003669s [Database: default]
        <UserInfo: UserInfo object (30)>
        ```
        
        첫 번째 순회 직전 for에서, id가 30 이하인 user들을 가져오는 쿼리를 실행한다.
        
        그리고 해당 user에 대응하는 userInfo를 가져오는 쿼리를 실행하는데, 이 쿼리를 매 순회마다 하는 것을 확인할 수 있다. → sql문을 보면 알 수 있는데 애초에 쿼리 실행할 때, 대응하는 테이블을 가져오지 않기 때문 → _result_cache[0].userinfo가 없음
        
        **결론적으로 N명의 UserInfo를 확인하기 위해 N+1번의 쿼리를 실행하고 있다.**
        
    
    1. 해결: **selected_related()를 사용하여 userInfo를 즉시 한번에 가져온다.**
        
        ```python
        >>> a = User.objects.filter(id__lte=30).select_related('userinfo')
        >>> for aa in a:
        ...     aa.userinfo
        ... 
        SELECT "orm_practice_app_user"."id",
               "orm_practice_app_user"."password",
               "orm_practice_app_userinfo"."id",
               "orm_practice_app_userinfo"."tel_num"
          FROM "orm_practice_app_user"
         INNER JOIN "orm_practice_app_userinfo"
            ON ("orm_practice_app_user"."userinfo_id" = "orm_practice_app_userinfo"."id")
         WHERE "orm_practice_app_user"."id" <= 30
        
        Execution time: 0.018662s [Database: default]
        <UserInfo: UserInfo object (1)>
        <UserInfo: UserInfo object (2)>
        ...
        <UserInfo: UserInfo object (30)>
        ```
        
        위의 에제와 마찬가지로 첫 번째 순회 직전 for에서, id가 30 이하인 user들을 가져오는 쿼리를 실행한다. 더불어 select_related로 inner join해서 대응하는 userinfo까지 한번에 가져와
        
        별도의 쿼리 필요 없이 매 순회마다 캐싱된 userInfo를 출력하는 것을 확인할 수 있다.
        
        **결론적으로 N명의 UserInfo를 확인하기 위해 1번의 쿼리를 실행하고 있다.**
        
    
- **prefetch_related와 filter는 서로 독립적이다.**
    
    의도: company의 name이 ‘company_name1’인 company와, 이에 대응하는 name이 null이 아닌 product도 즉시 로딩하고 싶어!
    
    - 안좋은 예
        
        ```python
        Company.objects
                .filter(name='company_name1', product__name__isnull=False)
                .prefetch_related('product_set')
        '''
        SELECT "orm_practice_app_company"."id",
               "orm_practice_app_company"."name",
               "orm_practice_app_company"."tel_num",
               "orm_practice_app_company"."address"
        FROM "orm_practice_app_company"
        INNER JOIN "orm_practice_app_product" ON ("orm_practice_app_company"."id" = "orm_practice_app_product"."product_owned_company_id")
        WHERE ("orm_practice_app_company"."name" = 'company_name1'
               AND "orm_practice_app_product"."name" IS NOT NULL)
        LIMIT 21
        
        SELECT "orm_practice_app_product"."id",
               "orm_practice_app_product"."name",
               "orm_practice_app_product"."price",
               "orm_practice_app_product"."product_owned_company_id"
        FROM "orm_practice_app_product"
        WHERE "orm_practice_app_product"."product_owned_company_id" IN (1)
        '''
        ```
        
        .filter 조건에 product__name__isnull=False로 해서 product와 inner join이 추가되었다.
        
        이후 .prefetch_related로 다시 product를 쿼리한다.
        
        product를 두 번 불러오고 있음 → 비효율
        
    - 해결 1: prefetch_related를 삭제
        
        ```python
        >>> Company.objects.filter(name='company_name1', product__name__isnull=False)
        SELECT "orm_practice_app_company"."id",
               "orm_practice_app_company"."name",
               "orm_practice_app_company"."tel_num",
               "orm_practice_app_company"."address"
          FROM "orm_practice_app_company"
         INNER JOIN "orm_practice_app_product"
            ON ("orm_practice_app_company"."id" = "orm_practice_app_product"."product_owned_company_id")
         WHERE ("orm_practice_app_company"."name" = 'company_name1' AND "orm_practice_app_product"."name" IS NOT NULL)
         LIMIT 21
        ```
        
    - 해결2: filter절에 넣었던 product 관련 조건을 prefetch에 제공
        
        추가쿼리의 where절이 수정된다.
        
        ```python
        >>> Company.objects.filter(name='company_name1').prefetch_related(Prefetch('product_set', queryset=Product.objects.filter(name__isnull=False)))
        SELECT "orm_practice_app_company"."id",
               "orm_practice_app_company"."name",
               "orm_practice_app_company"."tel_num",
               "orm_practice_app_company"."address"
          FROM "orm_practice_app_company"
         WHERE "orm_practice_app_company"."name" = 'company_name1'
         LIMIT 21
        
        Execution time: 0.023261s [Database: default]
        SELECT "orm_practice_app_product"."id",
               "orm_practice_app_product"."name",
               "orm_practice_app_product"."price",
               "orm_practice_app_product"."product_owned_company_id"
          FROM "orm_practice_app_product"
         WHERE ("orm_practice_app_product"."name" IS NOT NULL AND "orm_practice_app_product"."product_owned_company_id" IN (1))
        
        Execution time: 0.005195s [Database: default]
        ```
        
- 서브 쿼리
    
    작성 예정