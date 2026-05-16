---
title: "transaction isolation level"
---

# transaction isolation level

Status: database

[transaction isolation level 설명합니다! isolation이 안될 때 나타날 수 있는 여러 현상들과 snapshot isolation도 같이 설명합니다!!](https://www.youtube.com/watch?v=bLLarZTrebU&list=PLcXyemr8ZeoREWGhhZi5FZs6cvymjIBVe&index=17)

위의 영상을 참고 했습니다.

- 트랜잭션의 ACID 속성
    
    ACID는 데이터베이스 트랜잭션의 속성을 나타내는 네 가지 핵심 속성의 약어입니다. 각 글자는 다음과 같은 의미를 가지고 있습니다:
    
    1. **원자성 (Atomicity):** 트랜잭션은 원자적(Atomic)이어야 합니다. 이것은 트랜잭션의 모든 단계가 성공하거나 실패하면 전체 트랜잭션이 성공하거나 실패해야 함을 의미합니다. 어떤 단계에서라도 오류가 발생하면 트랜잭션은 롤백되어 이전 상태로 돌아가야 합니다.
    2. **일관성 (Consistency):** 트랜잭션은 일관성 있는 상태로 데이터베이스를 변경해야 합니다. 트랜잭션이 시작 전과 종료 후에도 데이터베이스는 일관성 있는 상태여야 합니다. 다시 말해, 트랜잭션은 정의된 비즈니스 규칙을 따라야 합니다.
    3. **고립성 (Isolation):** 동시에 여러 트랜잭션이 수행될 때 각 트랜잭션은 다른 트랜잭션에서 수행 중인 작업에 영향을 미치지 않도록 격리되어야 합니다. 트랜잭션은 다른 트랜잭션이 완료되기를 기다릴 필요가 없이 각자 독립적으로 실행되어야 합니다.
    4. **지속성 (Durability):** 트랜잭션이 성공적으로 완료되면 그 결과는 영구적으로 유지되어야 합니다. 시스템의 장애 또는 기타 문제로 인해 시스템이 중단되더라도 트랜잭션의 결과는 손실되지 않아야 합니다.

### isolation이 제대로 되지 않을 시, 발생하지 않는 현상

- **Dirty Read**: 커밋되지 않은 변경사항을 읽음
    
    ![Untitled](transaction%20isolation%20level/Untitled.png)
    
    - tx1 실행 도중, 커밋되지 않은 롤백된 tx2의 write(y=70) 변경사항을 읽어 데이터 정합성을 위배한다.
- **Non-repeatable read (Fuzzy read)**: 같은 데이터의 값이 달라짐
    
    ![Untitled](transaction%20isolation%20level/Untitled%201.png)
    
    - tx1이 동일한 데이터 x를 읽었는데 첫 번째와 두 번째의 값이 다르게 나왔다.
    - 여러 트랜잭션이 동시에 실행돼도 각각의 트랜잭션이 마치 혼자 실행되는 것 처럼 되어야 한다는 isolation 속성에 위배된다.
- **Phantom read**: 없던 데이터가 생김
    
    ![Untitled](transaction%20isolation%20level/Untitled%202.png)
    
    - 한 트랜잭션 안에서 동일한 조건으로 두 번 읽었는데, 각각의 결과가 다르게 나옴
- **Dirty write:** commit 안된 데이터를 write 함
    
    ![x 초기값 = 0](transaction%20isolation%20level/Untitled%203.png)
    
    x 초기값 = 0
    
    - tx1 이 abort나서 rollback하면 write(x=10)동작 하기 전의 x값, 즉 x=0이 된다. 그러면 tx2의 write(x=100) 동작이 무의미해짐.
    - 만약 tx2가 abort 한다고 해도, 롤백하려고 write(x=100)동작 하기 전의 x값, 즉  x=10으로 롤백하게 되는데 이 또한 abort된 값으로 된다.
    - **rollback 시, 정상적인 recovery는 매우 중요하기 때문에 모든 isolation level에서 dirty write를 허용하면 안된다.**
- **Lost update**: 업데이트를 덮어씀
    
    ![x의 초기값 = 50](transaction%20isolation%20level/Untitled%204.png)
    
    x의 초기값 = 50
    
    - 두 트랜잭션이 정상적으로 실행을 했는데, tx2의 내용은 무효가 되어 버림.
    - 만약 순차적으로 트랜잭션을 실행 했다면 x의 값은 250이었겠지만, 겹쳐서 실행되어 tx1이 tx2를 덮어씌움
- **Dirty read 확장판**: 롤백을 하지 않아도 dirty read가 발생할 수 있다
    
    ![x,y 가 각각의 계좌라고 상정](transaction%20isolation%20level/Untitled%205.png)
    
    x,y 가 각각의 계좌라고 상정
    
    - x,y가 각각의 계좌이기 때문에 두 계좌 금액의 총 합은 항상 같아야 한다.
    - 하지만 tx2에서는 총 합이 60이기 때문에 데이터 정합성에 위배됨. (커밋되지 않은 데이터를 읽었기 때문에)
- Read skew: inconsistent한 데이터 읽기
    
    ![x,y가 각각의 계좌라고 상정](transaction%20isolation%20level/Untitled%206.png)
    
    x,y가 각각의 계좌라고 상정
    
    - 서로 관련 없는 x,y를 읽었음에도 총합이 140으로 일치하지 않는다
    - non-repeatable과 비슷한데 서로 관련 없는 x,y가 불일치 하다는 점이 차이점
- Write skew: inconsistent한 데이터 쓰기
    
    ![x+y ≥ 0 제약사항이 있다](transaction%20isolation%20level/Untitled%207.png)
    
    x+y ≥ 0 제약사항이 있다
    
    - 만약 순차적으로 잘 트랜잭션들이 실행 됐다면, tx2는 x+y ≥ 0 제약사항에 위반되어 abort가 났어야 한다.
    - 서로 다른 데이터 x,y 에 write 작업을 했음에도 데이터 불일치한 쓰기가 됨
- Phantom read 확장판:
    
    ![Untitled](transaction%20isolation%20level/Untitled%208.png)
    
    - tx1에서 v>10인 튜플을 읽었지만 없기 때문에 아무것도 읽지 않았다.
    - 하지만 read(cnt) 하기 전 tx2 에서 v=15인 튜플을 insert 했기 때문에 cnt =1이 됐다.
    - 그래서 read(cnt) = 1이 되어 tx1 안에서 데이터 불일치가 발생함.
    - 이 처럼 한 트랜잭션 안에 같은 데이터가 아닌, 서로 연관된 데이터사이에서 데이터 불일치가 되는 경우도 phantom read라고 볼 수 있다.

### snapshot isolation

- concurrency control 구현하기 위해 정의된 isolation level
- 트랜잭션이 시작한 시점을 기준으로 스냅샷을 찍어 형상관리를 함
- tx 시작 전의 commit된 데이터만 보임
- First-committer win
- 동작방식 예
    1. read(x) ⇒ 50: tx1이 시작한 시점의 스냅샷의 x값을 읽는다
        
        ![Untitled](transaction%20isolation%20level/Untitled%209.png)
        
    2. write(x=10): db에 write하는게 아닌, tx1의 스냅샷에 write한다.
        
        ![Untitled](transaction%20isolation%20level/Untitled%2010.png)
        
        외부에서 볼 땐 여전히 x = 50
        
    3. read(y)⇒ 50: tx2가 시작되고, 이 시점의 스냅샷의 y값을 읽는다
        
        ![Untitled](transaction%20isolation%20level/Untitled%2011.png)
        
    4. write(y = 150): 마찬가지로 db가 아닌 tx2의 스냅샷에 write 한다.
        
        ![Untitled](transaction%20isolation%20level/Untitled%2012.png)
        
    5. tx2가 commit되는 순간, 스냅샷의 변경사항이 db에 적용된다.
        
        ![Untitled](transaction%20isolation%20level/Untitled%2013.png)
        
    6. read(y) ⇒ 50: 이어서 tx1에서 y를 읽는데, tx1의 스냅샷의 y를 읽는다
        
        ![Untitled](transaction%20isolation%20level/Untitled%2014.png)
        
    7. tx1에서 write 작업까지 하고 commit을 할 때
        - tx1과 tx2가 같은 데이터 y에 대해 쓰기 작업을 한다.
        - 만약 tx1가 commit되면 y=90으로 바뀌어 tx2의 업데이트를 덮어 씌우게 된다.
        - snapshot isolation에는, 이렇게 write conflict가 발생할 때 먼저 commit한 transaction만 인정되고, 뒤에 commit된 tx는 abort처리 된다

### 트랜잭션의 격리 수준

[MySQL :: MySQL 5.7 Reference Manual :: 14.7.2.1 Transaction Isolation Levels](https://dev.mysql.com/doc/refman/5.7/en/innodb-transaction-isolation-levels.html)

- 데이터베이스 처리 개념 중 하나. (ACID중 I이다.)
- 데이터베이스에서 여러 트랜잭션이 동시에 실행될 때 어떻게 상호 작용 하는지를 나타내는 개념
- 격리 수준은 **여러 트랜잭션이 동시에 변경을 수행하고 쿼리를 수행할 때** 성능과 신뢰성, 일관성 및 결과의 재현성(reproducibility) 간의 **균형을 조정**하는 설정이다.
- SQL:1992 표준에서 소개한 4개의 level 이외에도 몇가지 더 있다. (READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE)
    
    ![Untitled](transaction%20isolation%20level/Untitled%2015.png)
    

### mysql의 격리수준

InnoDB는 SQL:1992 표준에서 설명한 네 가지 트랜잭션 격리 수준을 모두 지원한다.: READ UNCOMMITTED, READ COMMITTED, REPEATABLE READ, SERIALIZABLE.

1. **READ UNCOMMITTED (커밋되지 않은 읽기):**
    - 트랜잭션에서 변경 중인 데이터에 대한 읽기가 허용된다.
    - 다른 트랜잭션이 아직 커밋되지 않은 데이터를 읽을 수 있으므로 데이터 일관성이 낮다.
    - Dirty Read(더티 리드), Non-Repeatable Read, Phantom Read 등의 이상 현상이 발생할 수 있다.
2. **READ COMMITTED (커밋된 읽기):**
- **read하는 시간 기준으로 그 전에 commit된 데이터를 읽는다.**
- 트랜잭션이 커밋된 데이터만을 읽을 수 있다.
- Dirty Read는 방지됩니다. 하지만 Non-Repeatable Read와 Phantom Read와 같은 다른 이상 현상이 발생할 수 있다.
1. **REPEATABLE READ (반복 가능한 읽기):**
    - **트랜잭션 시작 시간 기준으로 그 전에 commmit된 데이터를 읽는다.**
    - 동일한 트랜잭션 내에서는 처음 수행된 일관된 읽기에 의해 설정된 스냅샷을 사용한다.
    - Non-Repeatable Read는 방지되지만, Phantom Read와 같은 이상 현상이 발생할 수 있다.
    - InnoDB의 기본 기본 격리 수준이다.
        
        ```bash
        mysql> show session variables like "%transaction_isolation%";
        +-----------------------+-----------------+
        | Variable_name         | Value           |
        +-----------------------+-----------------+
        | transaction_isolation | REPEATABLE-READ |
        +-----------------------+-----------------+
        ```
        
2. **SERIALIZABLE (직렬화):**
    - 가장 높은 격리 수준으로, 트랜잭션 간의 상호 작용을 완전히 분리한다.
    - 다른 트랜잭션에서의 변경을 허용하지 않고, 모든 읽기와 쓰기가 순차적으로 이루어진다.
    - Dirty Read, Non-Repeatable Read, Phantom Read 등의 모든 이상 현상이 방지된다.

### REPEATABLE READ에서의 일관된 읽기(consistant read)

[MySQL :: MySQL 5.7 Reference Manual :: 14.7.2.3 Consistent Nonlocking Reads](https://dev.mysql.com/doc/refman/5.7/en/innodb-consistent-read.html)

- 일관된 읽기란 InnoDB가 다중 버전을 사용하여 쿼리에 **데이터베이스의 특정 시점의 스냅샷**을 제공하는 것을 의미한다.
- 쿼리는 해당 시점 이전에 커밋된 트랜잭션에 의해 수행된 변경 사항을 볼 수 있으며, 해당 시점 이후나 미커밋된 트랜잭션에 의한 변경 사항은 보이지 않는다.
- 트랜잭션 격리 수준이 **REPEATABLE READ**(기본 수준)로 설정된 경우, 한 트랜잭션 내에서 모든 일관된 읽기는 **해당 트랜잭션에서 처음으로 수행된 읽기**에 의해 설정된 스냅샷을 사용한다. 현재 트랜잭션을 커밋한 후에 새로운 쿼리를 실행함으로써 쿼리에 더 신선한 스냅샷을 얻을 수 있다.
    
    ```sql
    -- 트랜잭션 시작
    START TRANSACTION;
    
    -- UPDATE 또는 DELETE 등의 변경 작업이 수행됨
    UPDATE users SET status = 'active' WHERE user_id = 1;
    
    -- 최초로 수행된 일관된 읽기에 의해 스냅샷이 생성됨
    SELECT * FROM users WHERE user_id = 1;
    
    -- 트랜잭션이 완료될 때까지 스냅샷 유지
    
    -- 다른 일관된 읽기
    SELECT * FROM users WHERE user_id = 2;
    
    -- 트랜잭션 종료 (커밋 또는 롤백)
    COMMIT; -- 또는 ROLLBACK;
    ```
    
- 이 규칙의 예외는 동일한 트랜잭션 내의 이전 명령에서 수행된 변경 사항이 쿼리에 표시된다는 것이다. 이 예외로 인해 다음과 같은 이상 현상이 발생한다: 특정 테이블의 몇 개의 행을 업데이트하는 경우 SELECT 문에서는 업데이트된 행의 최신 버전을 볼 수 있지만 해당 행의 이전 버전도 볼 수 있습니다. 다른 세션에서 동시에 동일한 테이블을 업데이트하는 경우, 이 이상 현상은 데이터베이스에 실제로 존재하지 않은 상태의 테이블을 볼 수 있다는 의미입니다.
- **예** (read skew: **동일한 트랜잭션 내에서 발생하는 읽기 작업 중에 데이터의 일관성이 깨지는 현상**)
    
    ```sql
    트랜잭션 A:
    UPDATE users SET status = 'active' WHERE user_id = 1;
    SELECT * FROM users WHERE user_id = 1
    
    트랜잭션 B:
    UPDATE users SET status = 'inactive' WHERE user_id = 1;
    
    트랜잭션 A:
    SELECT * FROM users WHERE user_id = 1;
    ```
    
    위의 예시에서 트랜잭션 A의 첫 번째 **`SELECT`**문과 세 번째 **`SELECT`**문의 결과는 동일해야 한다. REPEATABLE READ 격리 수준에서는 한 트랜잭션 내에서 이전 명령에 의해 영향을 받은 변경 사항이 새로운 쿼리에도 영향을 미치지 않는다. **따라서 두 `SELECT`문은 모두 'active'로 업데이트된 최신 상태를 보여주어야 한다.**
    
    이 현상에서는 동일한 트랜잭션 내에서는 이전 명령의 영향을 받아 최신 및 이전 버전을 함께 볼 수 있지만, **다른 트랜잭션이 동시에 작업할 때는 데이터베이스의 실제 상태와는 다르게 보일 수 있다.**
    

### django에서 repeatable read는 어떻게 동작할까?

[select_for_update와 block test](select_for_update%EC%99%80%20block%20test%20a722089bb3584e4aaa24413bf0a4e88f.md)