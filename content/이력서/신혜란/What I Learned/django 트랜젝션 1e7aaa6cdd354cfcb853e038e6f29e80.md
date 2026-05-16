---
title: "django 트랜젝션"
---

# django 트랜젝션

Status: django

- try, except, else, finally
    
    이런 것도 갑자기 헷갈릴 때가 있다….😅
    
    ```python
    try:
        실행할 코드
    except:
        예외가 발생했을 때 처리하는 코드
    else:
        예외가 발생하지 않았을 때 실행할 코드
    finally:
        예외 발생 여부와 상관없이 항상 실행할 코드
    ```
    

## atomic

**`atomic`(*using=None*, *savepoint=True*, *durable=False*)**

아래 공식문서를 정리한 내용입니다.

[Django](https://docs.djangoproject.com/en/4.1/topics/db/transactions/#django.db.transaction.atomic)

- 원자성(Atomicity)은 데이터베이스 트랜젝션을 정의하는 속성 중 하나이다. atomic은 데이터베이스의 원자성이 보장되는 코드 블록을 생성할 수 있게 해준다. 만약 코드블록이 성공적으로 완료되면,  변경사항은 데이터베이스에 커밋된다. 만약 예외(exception)가 발생하면, 변경사항은 롤백된다.
- 일반적인 사용법 1,2: decorateor, context manager
    
    ```python
    from django.db import transaction
    	
    # decorator로 사용하기
    @transaction.atomic
    def viewfunc(request):
        do_stuff()
    
    # python context manager로 사용하기
    def viewfunc(request):
        do_stuff()
    
        with transaction.atomic():
            do_more_stuff()
    ```
    
- atomic 블록은 중첩될 수 있다. 이 경우 내부 블록이 완료되어도, 이후 외부 블록에서 exception이 일어난다면 롤백될 수 있다.
    - 다른 database를 사용하는 트랜잭션끼리도 중첩될 수 있다.
        
        ```python
        with transaction.atomic(using='default'):
        	with transaction.atomic(using='bank'):
        		...
        ```
        
    - atomic은 데이터베이스 이름이어야 하는 **using** 인자를 사용한다. 인자가 제공되지 않으면 “default” 데이터베이스를 사용한다.
    - **durable**=True: 데이터베이스 변경 사항이 오류 없이 빠져나올 때, **원자 블록이 항상 최상위 원자 블록으로 유지되도록 하는 것이 유용하다**. 만약 원자 블록이 다른 블록 **안에 중첩되어 있으면 RuntimeError가 발생**한다.
- transaction 안에서 natural error 핸들링: try/except블록을 atomic으로 감싸라
    
    ```python
    @transaction.atomic
    def viewfunc(request):
        create_parent()
    
        try:
            with transaction.atomic():
                generate_relationships()
        except IntegrityError:
            handle_exception()
    
        add_children()
    ```
    
    이 경우 generate_relationships에서 integrityError가 발생해도, **add_children함수에서는 쿼리를 실행할 수 있고, create_parent 함수에서의 변경 사항은 여전히 유지되며**, 동일한 트랜잭션에 바인딩 되어 있다. 그러나 generate_relationships 함수에서 시도한 모든 작업은 handle_exception()함수가 호출될 때 이미 안전하게 롤백 되었기 때문에, 예외 핸들러는 필요한 경우 데이터베이스에서도 작동할 수 있다.
    
- atomic안에 exception을 캐치하는 것을 피해라!
    
    ```python
    # avoid doing this!
    @transaction.atomic
    def viewfunc(request):
    	try:
    		do_stuff()
    	except Exception: # 이는 대부분 DatabaseError 및 IntegrityError와 같은 하위 클래스에서 주로 발생한다.
    		handle_exception()
    ```
    
    데이터베이스 오류를 올바르게 catch하려면 위와 같이 atomic블록 주위에 try-except문으로 추가해주면 된다. → **예외 발생시 롤백될 작업을 명시적으로 지정 가능**
    
- 원자성을 보장하기 위해, atomic은 일부 api를 비활성화한다. atomic 블록 안에서 데이터베이스 연결의 commit, rollback 또는 autocommit 상태 변경을 시도하면 예외가 발생한다.

### transaction.atomic(savepoint=False)

Django의 트랜잭션 관리 코드는 내부적으로 다음과 같은 작업을 수행합니다:

- 가장 바깥쪽의 **`atomic`** 블록에 진입할 때 트랜잭션을 엽니다.
- 내부 **`atomic`** 블록에 진입할 때 세이브포인트를 생성합니다.
- 내부 블록을 빠져나올 때 세이브포인트를 해제하거나 롤백합니다.
- 가장 바깥쪽 블록을 빠져나올 때 트랜잭션을 커밋하거나 롤백합니다.

**`savepoint`** 인수를 **`False`**로 설정하여 내부 블록에서 세이브포인트의 생성을 비활성화할 수 있다. 예외가 발생하면 Django는 첫 번째 세이브포인트가 있는 부모 블록을 나갈 때 롤백을 수행하고, 그렇지 않은 경우에는 가장 바깥쪽 블록에서 롤백을 수행한다. 외부 트랜잭션에 의해 여전히 원자성이 보장된다. 이 옵션은 세이브포인트의 오버헤드가 눈에 띄는 경우에만 사용해야 한다. 이것은 위에서 설명한 오류 처리를 파괴하는 단점이 있다.

**`autocommit`**이 비활성화된 상태에서 **`atomic`**을 사용할 수 있다. 이 경우 세이브포인트를 가장 바깥쪽 블록에서도 사용하고, 만약 가장 바깥쪽 블록이 **`savepoint=False`**로 선언된 경우에는 예외를 발생시킨다.

1. **`atomic`** 블록에 진입하면 트랜잭션이 열린다.
2. 내부 **`atomic`** 블록에 진입하면 세이브포인트가 생성된다. 그러나 여기서는 **`savepoint=False`**로 설정되어 세이브포인트 생성이 비활성화된다.
3. 내부 **`atomic`** 블록에서 예외가 발생하면 Django는 가장 바깥쪽에 있는 부모 **`atomic`** 블록으로 롤백한다. 이때 세이브포인트가 없기 때문에 바로 가장 바깥쪽 블록에서 롤백이 수행된다.
4. 이렇게 함으로써 외부 트랜잭션에 의해 여전히 원자성이 보장된다.

```python
from django.db import transaction

def example_function():
    try:
        with transaction.atomic():
            # Outermost atomic block
            print("Outermost block - Start")
            
            try:
                with transaction.atomic(savepoint=False):
                    # Inner atomic block with savepoint disabled
                    print("Inner block with savepoint disabled - Start")
                    # Perform some database operations
                    users = User.objects.filter(id = 1)
                    users.update(first_name = 'a')
                    
                    # Simulate an exception
                    raise ValueError("Simulated Exception")
                    print("Inner block with savepoint disabled - End")
            except ValueError:
                # Catch exception in the inner block
                print("Caught exception in inner block with savepoint disabled")

            # Continue with outer block operations
            # ...
            print("Outermost block - End")

    except Exception as top_exception:
        # Catch exception at the top level
        print("Caught exception at the top level:", top_exception)

# 실행
example_function()

''' savepoint = False
Outermost block - Start
Inner block with savepoint disabled - Start
UPDATE `auth_user`
SET `first_name` = 'a'
WHERE `auth_user`.`id` = 1

Caught exception in inner block with savepoint disabled
NONE

Outermost block - End
'''

''' savepoint = True
Outermost block - Start
SAVEPOINT `s4596147712_x1`

Inner block with savepoint abled - Start
UPDATE `auth_user`
SET `first_name` = 'a'
WHERE `auth_user`.`id` = 1

ROLLBACK TO SAVEPOINT `s4596147712_x1`

RELEASE SAVEPOINT `s4596147712_x1`

Caught exception in inner block with savepoint abled
Outermost block - End
'''
```

- 트랜젝션 테스트(간단 버전)
    - 한 개의 트랜젝션 롤백하는거 확인
        
        ```python
        @transaction.atomic
        def inner_transaction():
            company = Company.objects.first()
            print('변경 전 이름:'+company.name)
        
            company.name = company.name + '1'
            company.save()
        
            updated_company = Company.objects.first()
            print('변경 후 이름:'+updated_company.name)
            raise Exception
        
        def transaction_test1():
            try:
                inner_transaction()
            finally:
                company = Company.objects.first()
                print('현재 이름:'+company.name)
        
        transaction_test1()
        ```
        
        - 실행결과
            
            ```python
            BEGIN
            
            SELECT "main_company"."id",
                   "main_company"."ticker",
                   "main_company"."name"
            FROM "main_company"
            ORDER BY "main_company"."id" ASC
            LIMIT 1
            
            변경 전 이름:애플
            UPDATE "main_company"
            SET "ticker" = 'AAPL',
                "name" = '애플1'
            WHERE "main_company"."id" = 1
            
            SELECT "main_company"."id",
                   "main_company"."ticker",
                   "main_company"."name"
            FROM "main_company"
            ORDER BY "main_company"."id" ASC
            LIMIT 1
            
            변경 후 이름:애플1
            SELECT "main_company"."id",
                   "main_company"."ticker",
                   "main_company"."name"
            FROM "main_company"
            ORDER BY "main_company"."id" ASC
            LIMIT 1
            
            현재 이름:애플
            ```
            
        - inner transaction 도중에 .save()를 하여도 실제 데이터베이스에 반영되지 않는다. 트랜잭션이 안마쳤기 때문 → 변경 후 이름은 ‘애플1’이 나왔지만 이 시점에 데이터베이스 조회하면 ‘애플’로 나온다.
        - 당연히 트랜잭션 도중에 오류가 발생했기 때문에 롤백되어 다시 조회 해보면 ‘애플’이라고 나온다.
    
    - 다중 트랜잭션의 경우 어떻게 롤백하는지 확인
        - inner_transaction안에서 오류가 날 경우 outer_transaction에서의 change_db1과 change_db2는 롤백되는지
            
            ```python
            @transaction.atomic
            def outer_transaction():
                # change_db1
                user = User.objects.get(username='user0')
                print(f"유저의 전 이름:{user.first_name}")
                user.first_name = 'test'
                user.save()
            
                try:
                    inner_transaction()
                except:
                    user = User.objects.get(username='user0')
                    print(f"유저의 현재 이름:{user.first_name}")
                
                '''
                예상:
                    유저의 전 이름: 
                    유저의 현재 이름: test
                    유저의 트랜잭션 후 이름: test
                '''
            
            outer_transaction()
            user = User.objects.get(username='user0')
            print(f"유저의 트랜잭션 후 이름:{user.first_name}")
            ```
            
            - 실행결과
                
                ```python
                BEGIN
                
                SELECT "auth_user"."id",
                       "auth_user"."password",
                       "auth_user"."last_login",
                       "auth_user"."is_superuser",
                       "auth_user"."username",
                       "auth_user"."first_name",
                       "auth_user"."last_name",
                       "auth_user"."email",
                       "auth_user"."is_staff",
                       "auth_user"."is_active",
                       "auth_user"."date_joined"
                FROM "auth_user"
                WHERE "auth_user"."username" = 'user0'
                LIMIT 21
                
                유저의 전 이름:
                UPDATE "auth_user"
                SET "password" = 'password123123!',
                    "last_login" = NULL,
                    "is_superuser" = 0,
                    "username" = 'user0',
                    "first_name" = 'test',
                    "last_name" = '',
                    "email" = '',
                    "is_staff" = 0,
                    "is_active" = 1,
                    "date_joined" = '2023-07-05 08:35:23.660495'
                WHERE "auth_user"."id" = 2
                
                SAVEPOINT "s4562613760_x1"
                
                SELECT "main_company"."id",
                       "main_company"."ticker",
                       "main_company"."name"
                FROM "main_company"
                ORDER BY "main_company"."id" ASC
                LIMIT 1
                
                변경 전 이름:애플
                UPDATE "main_company"
                SET "ticker" = 'AAPL',
                    "name" = '애플1'
                WHERE "main_company"."id" = 1
                
                SELECT "main_company"."id",
                       "main_company"."ticker",
                       "main_company"."name"
                FROM "main_company"
                ORDER BY "main_company"."id" ASC
                LIMIT 1
                
                변경 후 이름:애플1
                ROLLBACK TO SAVEPOINT "s4562613760_x1"
                
                RELEASE SAVEPOINT "s4562613760_x1"
                
                SELECT "auth_user"."id",
                       "auth_user"."password",
                       "auth_user"."last_login",
                       "auth_user"."is_superuser",
                       "auth_user"."username",
                       "auth_user"."first_name",
                       "auth_user"."last_name",
                       "auth_user"."email",
                       "auth_user"."is_staff",
                       "auth_user"."is_active",
                       "auth_user"."date_joined"
                FROM "auth_user"
                WHERE "auth_user"."username" = 'user0'
                LIMIT 21
                
                유저의 현재 이름:test
                SELECT "auth_user"."id",
                       "auth_user"."password",
                       "auth_user"."last_login",
                       "auth_user"."is_superuser",
                       "auth_user"."username",
                       "auth_user"."first_name",
                       "auth_user"."last_name",
                       "auth_user"."email",
                       "auth_user"."is_staff",
                       "auth_user"."is_active",
                       "auth_user"."date_joined"
                FROM "auth_user"
                WHERE "auth_user"."username" = 'user0'
                LIMIT 21
                
                유저의 트랜잭션 후 이름:test
                ```
                
                - SAVEPOINT "s4562613760_x1": 외부 트랜잭션에서 내부 트랜잭션을 실행하기 직전, 외부 트랜잭션의 savePoint를 생성한다
                - ROLLBACK TO SAVEPOINT "s4562613760_x1": 내부 트랜잭션에서 오류가 발생하여 내부 트랜잭션 실행하기 직전의 세이브 포인트로 롤백한다
                - RELEASE SAVEPOINT "s4562613760_x1": 이전 상태를 커밋하거나 롤백하지 않고, 해당 지점 이후로 진행된 트랜잭션을 계속 진행 하겠다
            - inner transaction 에서 오류가 발생하지 않은 경우
                
                ```python
                BEGIN
                
                SELECT "auth_user"."id",
                       "auth_user"."password",
                       "auth_user"."last_login",
                       "auth_user"."is_superuser",
                       "auth_user"."username",
                       "auth_user"."first_name",
                       "auth_user"."last_name",
                       "auth_user"."email",
                       "auth_user"."is_staff",
                       "auth_user"."is_active",
                       "auth_user"."date_joined"
                FROM "auth_user"
                WHERE "auth_user"."username" = 'user0'
                LIMIT 21
                
                유저의 전 이름:test
                UPDATE "auth_user"
                SET "password" = 'password123123!',
                    "last_login" = NULL,
                    "is_superuser" = 0,
                    "username" = 'user0',
                    "first_name" = 'test1',
                    "last_name" = '',
                    "email" = '',
                    "is_staff" = 0,
                    "is_active" = 1,
                    "date_joined" = '2023-07-05 08:35:23.660495'
                WHERE "auth_user"."id" = 2
                
                SAVEPOINT "s4356314624_x1"
                
                SELECT "main_company"."id",
                       "main_company"."ticker",
                       "main_company"."name"
                FROM "main_company"
                ORDER BY "main_company"."id" ASC
                LIMIT 1
                
                변경 전 이름:애플
                UPDATE "main_company"
                SET "ticker" = 'AAPL',
                    "name" = '애플1'
                WHERE "main_company"."id" = 1
                
                SELECT "main_company"."id",
                       "main_company"."ticker",
                       "main_company"."name"
                FROM "main_company"
                ORDER BY "main_company"."id" ASC
                LIMIT 1
                
                변경 후 이름:애플1
                RELEASE SAVEPOINT "s4356314624_x1"
                
                SELECT "auth_user"."id",
                       "auth_user"."password",
                       "auth_user"."last_login",
                       "auth_user"."is_superuser",
                       "auth_user"."username",
                       "auth_user"."first_name",
                       "auth_user"."last_name",
                       "auth_user"."email",
                       "auth_user"."is_staff",
                       "auth_user"."is_active",
                       "auth_user"."date_joined"
                FROM "auth_user"
                WHERE "auth_user"."username" = 'user0'
                LIMIT 21
                
                유저의 트랜잭션 후 이름:test1
                ```
                
                - 아까와 달리 rollback to savepoint가 없다!
            
        - transaction 중에 다른 프로세스에서 같은 db를 수정한다면 어떻게 될지
            
            ```python
            @transaction.atomic
            def test_transaction(): 
                now = timezone.localtime()
                user = User.objects.get(username='user0')
                print('변경 전 이름:'+user.first_name)
                user.first_name = f"{now.hour}시{now.minute}분{now.second}초"
                user.save()
            
                print('start sleep')
                time.sleep(15) # 이 사이에 다른 로우의 같은 필드, 같은 로우의 다른 필드, 같은 로우의 같은 필드 수정 해보기
                print('finish sleep')
                
                user = User.objects.get(username='user0')
                print('변경 후 이름:'+user.first_name)
            ```
            
            - 같은 테이블, 다른 로우의 경우
                - sqlite경우
                    
                    sleep동안 user1의 first name을 변경 해봤더니 다음과 같은 오류가 떴다.
                    
                    트랜잭션의 경우 해당 테이블의 쓰기 행동에 lock이 걸린 다는 것을 알 수 있다.
                    
                    ```python
                    Internal Server Error: /admin/auth/user/3/change/
                    Traceback (most recent call last):
                      "/.venv/lib/python3.9/site-packages/django/db/backends/utils.py", line 84, in _execute
                        return self.cursor.execute(sql, params)
                      File "/.venv/lib/python3.9/site-packages/django/db/backends/sqlite3/base.py", line 423, in execute
                        return Database.Cursor.execute(self, query, params)
                    sqlite3.OperationalError: database is locked
                    ```
                    
                - mysql경우 (test transaction을 연속으로 2회 실행)
                    
                    ```python
                    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
                    
                    SELECT `auth_user`.`id`,
                           `auth_user`.`password`,
                           `auth_user`.`last_login`,
                           `auth_user`.`is_superuser`,
                           `auth_user`.`username`,
                           `auth_user`.`first_name`,
                           `auth_user`.`last_name`,
                           `auth_user`.`email`,
                           `auth_user`.`is_staff`,
                           `auth_user`.`is_active`,
                           `auth_user`.`date_joined`
                    FROM `auth_user`
                    WHERE `auth_user`.`username` = 'user0'
                    LIMIT 21
                    
                    변경 전 이름:1
                    UPDATE `auth_user`
                    SET `password` = 'password123123!',
                        `last_login` = NULL,
                        `is_superuser` = 0,
                        `username` = 'user0',
                        `first_name` = '0시50분23초',
                        `last_name` = '',
                        `email` = '',
                        `is_staff` = 0,
                        `is_active` = 1,
                        `date_joined` = '2023-11-08 15:22:57'
                    WHERE `auth_user`.`id` = 1
                    
                    start sleep
                    finish sleep
                    SELECT `auth_user`.`id`,
                           `auth_user`.`password`,
                           `auth_user`.`last_login`,
                           `auth_user`.`is_superuser`,
                           `auth_user`.`username`,
                           `auth_user`.`first_name`,
                           `auth_user`.`last_name`,
                           `auth_user`.`email`,
                           `auth_user`.`is_staff`,
                           `auth_user`.`is_active`,
                           `auth_user`.`date_joined`
                    FROM `auth_user`
                    WHERE `auth_user`.`username` = 'user0'
                    LIMIT 21
                    
                    변경 후 이름:0시50분23초
                    [09/Nov/2023 00:50:38] "GET /test HTTP/1.1" 200 4
                    SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED
                    
                    SELECT `auth_user`.`id`,
                           `auth_user`.`password`,
                           `auth_user`.`last_login`,
                           `auth_user`.`is_superuser`,
                           `auth_user`.`username`,
                           `auth_user`.`first_name`,
                           `auth_user`.`last_name`,
                           `auth_user`.`email`,
                           `auth_user`.`is_staff`,
                           `auth_user`.`is_active`,
                           `auth_user`.`date_joined`
                    FROM `auth_user`
                    WHERE `auth_user`.`username` = 'user0'
                    LIMIT 21
                    
                    변경 전 이름:0시50분23초
                    UPDATE `auth_user`
                    SET `password` = 'password123123!',
                        `last_login` = NULL,
                        `is_superuser` = 0,
                        `username` = 'user0',
                        `first_name` = '0시50분38초',
                        `last_name` = '',
                        `email` = '',
                        `is_staff` = 0,
                        `is_active` = 1,
                        `date_joined` = '2023-11-08 15:22:57'
                    WHERE `auth_user`.`id` = 1
                    
                    start sleep
                    finish sleep
                    SELECT `auth_user`.`id`,
                           `auth_user`.`password`,
                           `auth_user`.`last_login`,
                           `auth_user`.`is_superuser`,
                           `auth_user`.`username`,
                           `auth_user`.`first_name`,
                           `auth_user`.`last_name`,
                           `auth_user`.`email`,
                           `auth_user`.`is_staff`,
                           `auth_user`.`is_active`,
                           `auth_user`.`date_joined`
                    FROM `auth_user`
                    WHERE `auth_user`.`username` = 'user0'
                    LIMIT 21
                    
                    변경 후 이름:0시50분38초
                    ```
                    
                    ```python
                    변경 전 이름:1
                    start sleep
                    finish sleep
                    변경 후 이름:0시50분23초
                    변경 전 이름:0시50분23초
                    start sleep
                    finish sleep
                    변경 후 이름:0시50분38초
                    ```
                    
                - sqlite와 mysql에 따라 다르게 나온 이유?
                    - 공식문서에 따르면 sqlite의 기본 격리 수준은 serializable이다.
                        
                        [Isolation In SQLite](https://www.sqlite.org/isolation.html)
                        
                        PRAGMA read_uncommitted가 켜져 있지 않은 공유 캐시 데이터베이스 연결의 경우, SQLite의 모든 트랜잭션은 "serializable" 격리를 나타냅니다. SQLite는 실제로 쓰기를 직렬화하여 진행합니다. SQLite 데이터베이스에는 한 번에 하나의 작성자만 있을 수 있습니다. 동시에 여러 개의 데이터베이스 연결이 열려 있을 수 있으며, 모든 데이터베이스 연결이 데이터베이스 파일에 쓸 수 있지만 차례대로 진행해야 합니다. SQLite는 자동으로 쓰기를 직렬화하기 위해 잠금을 사용하며, 이는 SQLite를 사용하는 응용 프로그램이 걱정할 필요가 없는 자동화된 프로세스입니다.
                        
                    - 반면 mysql의 경우 기본 격리 수준은 repeatable read이다.
                        
                        ```python
                        mysql> SELECT @@GLOBAL.transaction_isolation;
                        +--------------------------------+
                        | @@GLOBAL.transaction_isolation |
                        +--------------------------------+
                        | REPEATABLE-READ                |
                        +--------------------------------+
                        1 row in set (0.00 sec)
                        ```
                        
                

- docker shell 명령어
    
    ```python
    python manage.py shell_plus --print-sql
    docker-compose up -d
    ```