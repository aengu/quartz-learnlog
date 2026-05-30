---
title: "MVCC case study"
---

# MVCC case study

Status: database

[(1부) DB MVCC 개념 설명합니다 ! MVCC가 각각의 isolation level에서 어떻게 동작하는지도 MySQL & postgreSQL 예제와 함께 설명합니다](https://www.youtube.com/watch?v=wiVvVanI3p4&list=PLcXyemr8ZeoREWGhhZi5FZs6cvymjIBVe&index=19)

위의 영상을 참고하여 작성했습니다.

### mvcc 등장 배경

![[MVCC case study_Untitled.png]]

기존의 lock 기반의 동시성 제어는 같은 데이터에 대해 read/read하는 경우는 허용 하지만, 그 외의 경우들은 모두 허용x (한쪽에 실행되면 다른 한쪽은 블락이 되어 기다리게 됨) → 동시에 처리할 수 있는 처리량이 줄어 들어 퍼포먼스 저하

![[MVCC case study_Untitled 1.png]]

위 문제를 보완하기 위해 mvcc 등장. 같은 데이터에 대해 write/write하는 경우는 한 쪽이 블락되는 형태로 동작하지만 그외의 동작들은 허용

### mvcc의 동작 방식특징

- consistent read: **데이터를 읽을 때 특정 시점 기준으로 가장 최근에 commit된 데이터를 읽는다** (ex: read commited는 read하는 시간/ repeatable read에서는 트랜잭션이 시작한 시간)
- 데이터 변화(write)이력을 관리한다
- **read와 write는 서로를 block하지 않는다.(같은 데이터에 대해 write/write하는 경우는 한 쪽이 블락되지만 그외의 동작들은 허용)**
- 동시에 여러 트랜잭션이 데이터를 수정하더라도 충돌을 방지하고 일관성을 유지할 수 있다
- read uncommited: mvcc는 commited 데이터를 읽기 때문에 이 레벨에서는 보통 mvcc가 적용되지 않는다(postgresql에서는 존재는 하지만 read commited처럼 동작한다고 함)

### case study1: lost update 해결하기

초기값 x=50, y=10

tx1: x가 y에 40을 이체한다.

tx2: x에 30을 입금한다.

→ 정상적인 serializable하게 동작했다면(tx1→tx2 or tx2→tx1) **x=40, y=50이 되어야 한다.**

- test code
    - tx_decorator
        
        ```python
        def tx_decorator(func):
            def wrapper(*args, **kwargs):
                value = args[0]
                sleep_flag = args[1]
                print(f"tx{value} start")
                try:
                    with transaction.atomic():
                        func(*args, **kwargs)                
                        if sleep_flag:
                            time.sleep(10)
                except Exception as e:
                    print(f"tx{value}:{e}")
                    raise
                finally:
                    print(f"tx{value} end")
        
            return wrapper
        ```
        
    - init_account()
        
        ```python
        def init_account():
            Shares.objects.update_or_create(account_id=1, company_id=1, defaults={'amount':50})
            Shares.objects.update_or_create(account_id=2, company_id=1, defaults={'amount':10})
        ```
        
    - tx
        
        ```python
        @tx_decorator
        def tx1(value, sleep_flag=False): # x가 y에 40을 이체한다
            account_x = Shares.objects.get(account_id=1, company_id=1)
            account_y = Shares.objects.get(account_id=2, company_id=1)
            print(f"tx1의 x값:{account_x.amount}, tx1의 y값:{account_y.amount}")
            account_x.amount -= 40
            account_y.amount += 40
            account_x.save()
            account_y.save()
        ```
        
        ```python
        @tx_decorator
        def tx2(value, sleep_flag=False): # x에 30을 입금한다
            account_x = Shares.objects.get(account_id=1, company_id=1)
            account_y = Shares.objects.get(account_id=2, company_id=1)
            print(f"tx2의 x값:{account_x.amount}, tx2의 y값:{account_y.amount}")
            account_x.amount += 30
            account_x.save()
        ```
        
    - main
        
        ```python
        def mvcc_test():
            thread1 = threading.Thread(
                    target=tx1, args=('1',True) # tx1실행 중, tx2를 실행시키기 위해 임의로 대기
                )
            thread2 = threading.Thread(
                        target=tx2, args=('2',False)
                )
        
            init_account() # 초기값 설정
            thread1.start() # tx1이 먼저 실행되도록 임의로 sleep
            time.sleep(1)
            thread2.start()
        ```
        

- postgresql: read commited **(x=50, y=80)**
    
    ![[MVCC case study_Untitled 2.png]]
    
    **tx1에서 먼저 x에 대한 write lock을 취득했기 때문에 tx2의 x에 대한 write는 블락됨을 유의하자.**
    
    정상적으로 동작했다면 x=40, y=50이 되어야 하는데 **잘못된 결과가 나왔다.**
    
    ```python
    tx1 start
    tx1의 x값:50, tx1의 y값:10
    tx2 start
    tx2의 x값:50, tx2의 y값:10
    tx1 end
    tx2 end
    ```
    
    tx2가 x를 읽을 때, 50이 아닌, 10으로 읽었어야 했다. tx1가 업데이트한 x값이 tx2에 덮어짐 → **lost update 현상**
    
- postgresql: read repeatable **(x=10, y=50)**
    
    ![[MVCC case study_Untitled 3.png]]
    
    ```python
    tx1 start
    tx1의 x값:50, tx1의 y값:10
    tx2 start
    tx2의 x값:50, tx2의 y값:10
    tx1 end
    tx2:could not serialize access due to concurrent update
    tx2 end
    ```
    
    **first-updater-win: postgresql의 repeatable read에서는 같은 데이터에 먼저 updategks tx가 commit되면 나중 tx는 rollback된다.**
    
    따라서 tx1이 x,y를 수정한 뒤 commit하고, 이어서 tx2가 x를 수정하고 commit하려고 할 때 **tx2는 rollback된다.**
    
- mysql: repeatable read **(x=10, y=50)**
    
    ![[MVCC case study_Untitled 4.png]]
    
    postgresql에서 트랜잭션의 격리수준이 read commited일 때 Lost update현상이 일어나서 repeatable read로 격리수준을 올렸더니 해결되었다.
    
    **반면에 mysql에서는 first-updater-win이 적용되지 않아 격리수준이 repeatable read일 때도 lost update 현상이 발생하는 것을 확인할 수 있다.**
    
    - 영상에선 tx2가 먼저 실행되고, 중간에 tx1이 실행되기 때문에 main문 순서를 바꿨다.
        
        ```python
        def mvcc_test():
            thread1 = threading.Thread(
                    target=tx1, args=('1',False)
                )
            thread2 = threading.Thread(
                        target=tx2, args=('2',True)
                )
        
            init_account()
            thread2.start()
            time.sleep(1)
            thread1.start()
        ```
        
    
    ```python
    tx2 start
    tx2의 x값:50, tx2의 y값:10
    tx1 start
    tx1의 x값:50, tx1의 y값:10
    tx2 end
    tx1 end
    ```
    

- mysql: repeatable read + locking read (x=40, y=50)
    
    ![[MVCC case study_Untitled 5.png]]
    
    - account_x, account_y를 가져올 때 get()에서 filter.select_for_update().[0]으로 변경
        
        ```python
        @tx_decorator
        def tx1(value, sleep_flag=False): # x가 y에 40을 이체한다
            account_x = Shares.objects.filter(account_id=1, company_id=1).select_for_update()[0]
            account_y = Shares.objects.filter(account_id=2, company_id=1).select_for_update()[0]
            print(f"tx1의 x값:{account_x.amount}, tx1의 y값:{account_y.amount}")
            account_x.amount -= 40
            account_y.amount += 40
            account_x.save()
            account_y.save()
            
        
        @tx_decorator
        def tx2(value, sleep_flag=False): # x에 30을 입금한다
            account_x = Shares.objects.filter(account_id=1, company_id=1).select_for_update()[0]
            account_y = Shares.objects.get(account_id=2, company_id=1)
            print(f"tx2의 x값:{account_x.amount}, tx2의 y값:{account_y.amount}")
            account_x.amount += 30
            account_x.save()
        ```
        
    
    tx2가 먼저 시작되고 x를 read하며 write lock을 획득한다.
    
    ```python
    tx2 start
    
    SELECT `main_shares`.`id`,
           `main_shares`.`account_id`,
           `main_shares`.`company_id`,
           `main_shares`.`amount`,
    FROM `main_shares`
    WHERE (`main_shares`.`account_id` = 1
           AND `main_shares`.`company_id` = 1)
    LIMIT 1
    FOR
    UPDATE
    
    SELECT `main_shares`.`id`,
           `main_shares`.`account_id`,
           `main_shares`.`company_id`,
           `main_shares`.`amount`,
    FROM `main_shares`
    WHERE (`main_shares`.`account_id` = 2
           AND `main_shares`.`company_id` = 1)
    LIMIT 21
    
    tx2의 x값:50, tx2의 y값:10
    
    UPDATE `main_shares`
    SET `account_id` = 1,
        `company_id` = 1,
        `amount` = 80,
    WHERE `main_shares`.`id` = 1
    ```
    
    tx1이 이어서 시작되어 x에 대해 select_for_update를 하려는데 tx1이 x의 write lock을 갖고 있어 block되었다가 tx2가 commit되어 재개된다.
    
    ```python
    tx1 start
    
    SELECT `main_shares`.`id`,
           `main_shares`.`account_id`,
           `main_shares`.`company_id`,
           `main_shares`.`amount`,
    FROM `main_shares`
    WHERE (`main_shares`.`account_id` = 1
           AND `main_shares`.`company_id` = 1)
    LIMIT 1
    FOR
    UPDATE
    
    tx2 end
    SELECT `main_shares`.`id`,
           `main_shares`.`account_id`,
           `main_shares`.`company_id`,
           `main_shares`.`amount`,
    FROM `main_shares`
    WHERE (`main_shares`.`account_id` = 2
           AND `main_shares`.`company_id` = 1)
    LIMIT 1
    FOR
    UPDATE
    
    tx1의 x값:80, tx1의 y값:10
    UPDATE `main_shares`
    SET `account_id` = 1,
        `company_id` = 1,
        `amount` = 40,
    WHERE `main_shares`.`id` = 1
    
    UPDATE `main_shares`
    SET `account_id` = 2,
        `company_id` = 1,
        `amount` = 50,
    WHERE `main_shares`.`id` = 2
    
    tx1 end
    ```
    
    이때 tx1의 x값:80, tx1의 y값:10 으로 읽는데, repeatable read에서는 tx가 시작한 시점을 기준으로 commited 데이터를 읽기 때문에 x값:50, tx1의 y값:10으로 읽어야 하지만, mysql의 locking read는 격리수준과 상관없이 가장 최근의 데이터를 읽기 떄문에 80,10 으로 읽는다. → **정리하자면 mysql에서 lost update는 select_for_update로 해결할 수 있다!**
    

### case study2: write skew 해결하기

초기값 x=10, y=10

tx1: x = x+y

tx2: y = x+y

→ 정상적인 serializable하게 동작했다면 다음과 같이 되어야 한다.

1. tx1 → tx2: x=20, y=30
2. tx2 → tx1: x=30 y=20
- code
    - transaction
        
        ```python
        @tx_decorator
        def tx1(value, sleep_flag=False): # x = x+y
            account_x = Shares.objects.filter(account_id=1, company_id=1)[0]
            account_y = Shares.objects.filter(account_id=2, company_id=1)[0]
            print(f"tx1의 x값:{account_x.amount}, tx1의 y값:{account_y.amount}")
            account_x.amount += account_y.amount
            account_x.save()
            
        
        @tx_decorator
        def tx2(value, sleep_flag=False): # y = x+y
            account_x = Shares.objects.filter(account_id=1, company_id=1)[0]
            account_y = Shares.objects.filter(account_id=2, company_id=1)[0]
            print(f"tx2의 x값:{account_x.amount}, tx2의 y값:{account_y.amount}")
            account_y.amount += account_x.amount
            account_y.save()
        ```
        
    - init_account
        
        ```python
        def init_account():
            Shares.objects.update_or_create(account_id=1, company_id=1, defaults={'amount':10})
            Shares.objects.update_or_create(account_id=2, company_id=1, defaults={'amount':10})
        ```
        

- postgresql&mysql: repeatable read **(x=20, y=20) write skew**
    
    write skew: 서로 다른 데이터 x,y 에 write 작업을 했음에도 데이터 불일치한 쓰기가 되는 현상
    
    ![[MVCC case study_Untitled 6.png]]
    
    ```python
    tx1 start
    tx1의 x값:10, tx1의 y값:10
    tx2 start 
    tx2의 x값:10, tx2의 y값:10
    tx2 end
    tx1 end
    ```
    
- mysql: repeatable read **(x=20, y=30)** 해결
    
    ![[MVCC case study_Untitled 7.png]]
    
    tx1,2에 x,y read할 때 각각 locking read를 걸어주면 된다. tx1이 x에 대해 먼저 write lock를 취득했기 때문에 tx2는 블락되었다가 tx1이 commit된 후에 x,y를 읽는데, 이때 locking read이기 때문에 가장 최근의 데이터를 읽기 때문에 tx2의 x값:20, tx2의 y값:10로 읽어 정상적인 결과가 나왔다.
    
    ```python
    tx1 start
    tx1의 x값:10, tx1의 y값:10
    tx2 start
    tx1 end
    tx2의 x값:20, tx2의 y값:10
    tx2 end
    ```
    
- postgresql: repeatable read **(x=20, y=10)** 해결
    
    ![[MVCC case study_Untitled 8.png]]
    
    tx1에서 x에 대한 write lock을 먼저 취득했기 때문에 tx2는 대기한다. tx1이 커밋되고 tx2가 x에 대한 write lock을 취득해 read 하려고 할 때, x에 대해 tx1이 먼저 업데이트 했으므로 tx2는 rollback된다.
    
    ```python
    tx1 start
    tx1의 x값:10, tx1의 y값:10
    tx2 start
    tx1 end
    tx2:could not serialize access due to concurrent update
    tx2 end
    ```
    
    - could not serialize access due to concurrent update
        
        PostgreSQL에서 발생하는 오류로, 동시에 발생한 업데이트 작업으로 인해 트랜잭션이 직렬화할 수 없음을 의미한다. 이 오류는 일반적으로 동일한 데이터에 대한 동시 업데이트 작업이 발생하여 발생한다.