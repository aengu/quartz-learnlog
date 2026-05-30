---
title: "concurrency handling 동시성 제어 방법들"
---

# concurrency handling: 동시성 제어 방법들

Status: Not started

아래 발표 자료 일부를 정리한 내용입니다.

[https://github.com/pirate/django-concurrency-talk](https://github.com/pirate/django-concurrency-talk)

[Nick Sweeting - Database Integrity in Django - PyCon Colombia 2019](https://www.youtube.com/watch?v=rrlXAU-FGTo)

### 동시성을 없앤다

동시성 제어하고자 하는 모든 작업을 timestamp로 정렬하고 선형 queue에 넣고 빼며 별도의 프로세스로 실행한다 → 한 번에 한 요청만 처리하기 때문에 동시성, 경쟁조건이 발생할 일이 없다.

![[concurrency handling 동시성 제어 방법들_Untitled.png]]

### 동시성 제어 (ORM이 제공하는 도구들)

당연하지만 시스템이 일정 규모 이상으로 커지면, 1번은 속도면에서 비효율적일 수 밖에 없다. 따라서 동시성을 없애는 대신 제어해야 한다.

- atomic transaction
    
    ```python
    transaction.atomic()
    ```
    
- row locking (pessimistic	concurrency)
    
    락은 또 다른 도구로, 비관적 동시성이라고도 불린다. 다른 프로세스가 동시에 작업을 시도할 것이라고 가정하고, 그것을 막는 역할을 한다. 
    
    락에는 공유락, 베타락  두 가지가 있지만 django에서는 베타락(exclusive lock)만 지원한다. 공유락을 굳이 사용하고 싶다면 pure sql문으로 사용하면 된다고 한다.
    
    Django에서는 `select_for_update`를 사용하여 특정 쿼리셋에 락을 설정할 수 있다. 이는 다른 프로세스가 동일한 모델을 쓰려고 할 때 그 작업을 막아준다.
    
    락(lock)을 걸면 다른 스레드가 해당 행(row)을 현재 트랜잭션이 끝날 때까지 변경하지 못하도록 방지한다. 이 때, 락이 해제된다.
    
    ```python
    with transaction.atomic():
     to_update = Model.objects.select_for_update().filter(id=thing.id)
    
     ...
    
     to_update.update(val=new)
    ```
    
    만약 두 개의 프로세스가 모두 락을 획득하려고 시도하면 (예를 들어, 하나의 프로세스는 다른 모델에 대한 락이 필요한 모델을 수정하고, 다른 프로세스는 다른 모델에 대한 락이 필요한 모델을 가지고 있다고 가정), 교착 상태(deadlock)에 빠질 수 있다. 이 경우, 두 프로세스가 서로 락을 해제할 때까지 기다리는 상황이 발생한다. 
    
- compare and swaps, OCC (optimistic concurrency)
    
    비교 및 교환은 원자적인 연산으로, 동시에 두 프로세스가 동일한 연산을 수행할 수 없다고 가정한다. 항상 순서대로 실행되며, 이는 데이터베이스 레벨에서 동작한다. Django의 트랜잭션과 락없이 이러한 비교 및 교환 연산을 사용하여 동시성 문제를 해결할 수 있다.
    
    비교 교환은 낙관적 동시성(optimistic concurrency)이라고도 불리며, 이는 실제로 다른 프로세스가 동시에 모델을 수정하려 하지 않을 것이라고 가정하는 개념이다. (낙관적으로 이게 잘 작동하겠지~ 라고 기대함)
    
    ```python
    last_changed = obj.modified
    ...
    Model.objects.filter(id=obj.id, modified=last_changed).update(val=new_val)
    ```
    
    **동작 방식 (업데이트 버전 확인을 위해, version이나 modified같은 필드를 추가한다)**
    
    1. 데이터베이스에서 모델을 가져와서 먼저 버전 문자열이나 타임스탬프 같은 **마지막 수정 시간**을 읽는다.
    2. 그런 다음 모든 로직을 수행하고 데이터베이스에 커밋하기 직전에, **데이터베이스에 있는 버전이 로직을 수행할 때 내가 가져온 버전과 동일한지 확인한다.** 이를 통해 다른 프로세스가 로직을 수행하는 동안 이미 모델을 변경했는지 여부를 알 수 있다. 다른 프로세스가 이미 변경했다면 버전이 메모리에 있는 것과 다를 것이므로 실패하고 다시 시도한다.
    
    그러나 이것은 올바르게 구현하기가 매우 어렵다. 원자적 비교 교환을 수행할 때 발생할 수 있는 많은 실수가 있으며 조심해야 한다(이래서 낙관적 동시성).
    
    구현시 주의점
    
    - 락이 하나 이상의 모델을 동시에 수정해야 하는 경우, 모두를 트랜잭션 내에 넣어야 한다.
        - 예를 들어 여러 모델 사이에 종속적 관계가 있을 때, 부모 모델을 업데이트 하면 자식 모델을 업데이트 해야 하는 경우에 두 모델을 업데이트 하는 코드를 한 코드블럭에 넣어야 한다고 하는 것 같다.
    - 버전을 확인하는 부분과 쓰는 부분은 두 개의 다른 라인으로 나눌 수 없다.
        - 버전을 확인하고 기록하는 작업이 모두 한 라인에서 이루어져야 한다. 이를 위해 버전을 확인하고, 해당 버전일 경우 업데이트를 수행하고, 그렇지 않으면 실패로 처리하는 방식으로 처리해야 한다.
    
- Hybrid Solution ( optimistic concurrency+pessimistic or Multiversion Concurrency Control)
    
    **MVCC**
    
    - 자세한 내용은 여기에 따로 포스팅
        
        [MVCC case study](MVCC%20case%20study%208f7c0ebc9b2e4a82bb78e0db71034e92.md) 
        
    - consistent read: 데이터를 읽을 때 특정 시점 기준으로 가장 최근에 commit된 데이터를 읽는다 (ex: mysql에서는 read commited는 read하는 시간/ repeatable read에서는 트랜잭션이 시작한 시간)
    - 데이터 변화(write)이력을 관리한다
    - read와 write는 서로를 block하지 않는다.(같은 데이터에 대해 write/write하는 경우는 한 쪽이 블락되지만 그외의 동작들은 허용)
    - 동시에 여러 트랜잭션이 데이터를 수정하더라도 충돌을 방지하고 일관성을 유지할 수 있다.
    
    ```python
    last_changed = obj.modified
    ... read phase
    Model.objects.select_for_update().filter(id=obj.id, modified=last_changed)
    ... write phase
    ```
    
    ```python
    @transaction.atomic
    def read_and_update_data(obj):
        # read phase
        last_changed = obj.modified
        some_data = obj.some_field + 1
        
        # write phase
        with transaction.atomic():
            # select_for_update를 사용하여 락을 획득
            some_model_instance = SomeModel.objects.select_for_update().filter(id=obj.id, modified=last_changed).first()
            
            # 데이터 수정
            some_model_instance.some_field = some_data
            some_model_instance.save()
        
        return some_model_instance, some_data
    ```
    
    로직을 두 단계로 나눠서 읽기 단계와 쓰기 단계로 나눕니다. 읽기 단계에서는 낙관적 동시성을 사용하여 버전을 확인하고 로직을 수행하며, 쓰기 단계에서는 해당 버전을 가진 모델에 대해 락을 얻고 매우 짧은 기간 동안 모든 작업을 한 번에 수행한다. 이를 MVCC(Multi-Version Concurrency Control)라고 한다.
    
    MVCC는 동시에 여러 트랜잭션이 발생하는 환경에서 데이터 일관성을 유지하기 위한 방법 중 하나이다.
    
    MVCC에서는 각 트랜잭션에 대해 데이터의 여러 버전을 관리한다. 각 버전은 특정 시점에서의 데이터 상태를 나타낸다. 이를 통해 동시에 여러 트랜잭션이 데이터를 수정하더라도 충돌을 방지하고 일관성을 유지할 수 있다.
    
    MVCC의 핵심 원리는 다음과 같다:
    
    1. **읽기 단계:**
        - **`obj.modified`** 값을 읽어와서 현재 객체의 마지막 변경 시점을 기억
    2. **락을 건 후 읽기 단계:**
        - **`select_for_update()`**를 사용하여 해당 객체에 락을 걸어 다른 트랜잭션이 동시에 해당 객체를 수정하지 못하도록 한다.
    3. **쓰기 단계:**
        - 필요한 로직을 수행한 후, 다시 한 번 현재 객체의 **`modified`** 값을 확인하여 동시에 다른 트랜잭션이 수정하지 않았는지 확인한다.
    
    이러한 방식으로 코드는 읽기와 쓰기 단계를 통해 객체를 안전하게 업데이트하고, **`select_for_update()`**를 통해 락을 사용하여 다른 트랜잭션과의 충돌을 방지하므로 MVCC의 특징을 나타낸다.
    
    - 읽기, 쓰기 단계를 나누는 이유?
        
        MVCC(Multi-Version Concurrency Control)에서는 read phase와 write phase를 나누는 것이 dead lock을 피하기 위한 한 가지 전략이다. MVCC에서는 여러 버전의 데이터를 허용하고, 트랜잭션이 특정 버전을 읽어오는 동안 다른 트랜잭션이 해당 버전을 수정하더라도 서로간에 간섭하지 않는다.
        
        Read phase에서는 트랜잭션이 현재의 데이터 버전을 읽어오고, Write phase에서는 해당 버전이 여전히 유효한지를 확인하고 데이터를 수정하는 과정이 진행된다. 이렇게 버전을 확인하는 과정에서 다른 트랜잭션이 이미 해당 버전을 수정하고 커밋했다면, 현재 트랜잭션은 실패하게 된다. 이로써 다른 트랜잭션과의 간섭을 최소화하고, 동시성을 유지할 수 있다.
        
    

- 추가로 포스팅 할 거: create, update 같은 메서드 오버라이딩 할 때 차이점: rest api에서 serializer의 create, update/ viewset에서 & model정의할 때 save랑 model manager의 update/create 오버라이딩 등