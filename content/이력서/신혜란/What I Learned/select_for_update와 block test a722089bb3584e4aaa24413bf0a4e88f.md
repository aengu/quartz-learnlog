---
title: "select_for_update와 block test"
---

# select_for_update와 block test

Status: django

[](https://github.com/6ft/django/blob/2779f5e18163551c9ca36d5c239a6afd8ad9d961/docs/ref/models/querysets.txt#L1350)

테스트코드는 해당 문서를 참고 했습니다. (문서는 1.6이전 버전, 본 포스팅은 3.2.7)

- 차이점
    
    1.6버전 이전: 트랜잭션을 *transaction.enter_transaction_management(), transaction.commit(),transaction.abort()*등 트랜잭션 시작 끝 롤백을 임의로 지정해야 했다
    
    ```python
    def run_select_for_update(self, status, nowait=False):
            """
            Utility method that runs a SELECT FOR UPDATE against all
            Person instances. After the select_for_update, it attempts
            to update the name of the only record, save, and commit.
    
            This function expects to run in a separate thread.
            """
            status.append('started')
            try:
                # We need to enter transaction management again, as this is done on
                # per-thread basis
                    transaction.enter_transaction_management()
                    people = list(
                        Person.objects.all().select_for_update(nowait=nowait)
                    )
                    people[0].name = 'Fred'
                    people[0].save()
                    transaction.commit()
            except DatabaseError as e:
                status.append(e)
            finally:
                # This method is run in a separate thread. It uses its own
                # database connection. Close it without waiting for the GC.
                transaction.abort()
                connection.close()
    ```
    
    1.6버전 이후: transaction.atomic으로 데코레이터나 컨텐스트매니저로 관리한다.
    
    ```python
    
    def run_select_for_update(self, status, nowait=False):
            """
            Utility method that runs a SELECT FOR UPDATE against all
            Person instances. After the select_for_update, it attempts
            to update the name of the only record, save, and commit.
    
            This function expects to run in a separate thread.
            """
            status.append('started')
            try:
                with transaction.atomic:
                # We need to enter transaction management again, as this is done on
                # per-thread basis
                    people = list(
                        Person.objects.all().select_for_update(nowait=nowait)
                    )
                    people[0].name = 'Fred'
                    people[0].save()
            except DatabaseError as e:
                status.append(e)
    ```
    
    트랜잭션이 끝날 때까지 행을 잠그는 쿼리셋을 반환하며, 지원되는 데이터베이스에서는 **`SELECT ... FOR UPDATE`** SQL 문을 생성한다.
    

MySQL의 InnoDB 엔진에서 REPEATABLE READ 격리 수준을 사용하는 경우, 한 트랜잭션 내에서 읽기 및 쓰기 작업에 대한 동작은 다음과 같다.

1. **읽기 작업(Reads within the Same Transaction):** 트랜잭션 내에서 일관된 읽기(read)는 첫 번째 읽기에 의해 설정된 스냅샷을 읽는다. 즉, 동일한 트랜잭션 내에서 여러 번의 읽기 작업이 있더라도 첫 번째 읽기에 의해 설정된 스냅샷을 기준으로 한다. 이로써 일관성을 유지한다.
2. **잠금 읽기(For Locking Reads - SELECT with FOR UPDATE or LOCK IN SHARE MODE), UPDATE, DELETE 작업:** 이 경우, 잠금은 sql문이 고유 검색 조건을 사용하는지 또는 범위 유형 검색 조건을 사용하는지에 따라 달라진다.
    - **고유 검색 조건을 사용하는 경우:** InnoDB는 찾은 인덱스 레코드만 잠근다. Gap이 아닌 레코드만을 잠그므로 그 이전의 갭은 잠기지 않는다.
    - **기타 검색 조건을 사용하는 경우:** InnoDB는 검색된 인덱스 범위를 잠근다. 이때 갭 잠금 또는 다음 키 잠금을 사용하여 범위에 대한 간섭을 방지한다.

이러한 방식으로 InnoDB는 REPEATABLE READ 격리 수준에서 트랜잭션 내에서 일관성을 유지하면서 잠금을 관리한다.

모든 매치된 항목은 트랜잭션 블록이 끝날 때까지 잠겨 있게되며, 이는 다른 트랜잭션이 이러한 행을 변경하거나 잠금을 획득하는 것을 방지한다.

보통, 이미 다른 트랜잭션이 선택한 행에 대한 잠금을 획득한 경우, 쿼리는 해당 잠금이 해제될 때까지 블록된다. 이 동작이 원하는 동작이 아닌 경우에는 **`select_for_update(nowait=True)`**를 사용하면 된다(대기 하지 않음).  

- 쿼리가 블록 된다는 것?
    
    쿼리가 블록된다는 것은 해당 쿼리가 실행되고 있는 트랜잭션에서 이미 잠긴 행에 대한 잠금을 획득하려고 시도했지만, 다른 트랜잭션에서 이미 해당 행에 대한 잠금을 보유하고 있어서 대기하고 있는 상태를 의미한다. 다시 말해, 특정 행에 대한 잠금을 획득하려는데 이미 다른 트랜잭션에서 해당 행에 대한 잠금을 보유하고 있다면, 쿼리는 해당 잠금이 해제될 때까지 기다리게 된다.
    
    **`select_for_update(nowait=True)`**를 사용하면 블록되지 않고 즉시 반환되는데, 만약 다른 트랜잭션에서 이미 해당 행에 대한 잠금을 보유하고 있다면 **`DatabaseError`**가 발생합니다. 이를 통해 사용자는 쿼리가 즉시 실행되지 않을 때의 대기 상태를 피할 수 있다.
    

---

### vscode에서 django unittest 디버깅 하기

launch.py를 다음과 같이 생성

```python
# configuration file launch.py

{
    "version": "0.2.0",
    "configurations": [
      {
        "name": "Python: unittest",
        "type": "python",
        "request": "launch",
        "program": "${workspaceFolder}/transaction_practice_project/manage.py",
        "args": [
          "test",
          "unit_test.tests"  // 특정 테스트 케이스 지정
        ],
        "env": {
          "DJANGO_SETTINGS_MODULE": "transaction_practice_project.settings"
        },
        "cwd": "${workspaceFolder}"
      }
    ]
}
```

### django unnit test 실행 커맨드

```python
# 모든 테스트 실행
./manage.py test

# 특정 패키지의 테스트 실행
./manage.py test myapp.tests

# 특정 모듈의 테스트 실행
./manage.py test myapp.tests.test_module

# 특정 TestCase 하위 클래스의 테스트 실행
./manage.py test myapp.tests.test_module.TestClass

# 특정 테스트 메서드 실행
./manage.py test myapp.tests.test_module.TestClass.test_method
```

### mysql로 테스트 진행 시 isolation level 직접 설정

연결된 db에 설정된 isolation level로 진행된다고 알고 있는데, 막상 read commited로 실행되고 있었다.

다음과 같이 option에 직접 지정해주었더니 잘 됐다.

```python
DATABASES = {
    'default' : {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'trst',
        'USER': 'root',
        'PASSWORD': '',
        'HOST': '127.0.0.1',
        'OPTIONS':{
            'isolation_level': 'REPEATABLE READ',
        },
        'PORT': '3306',
    }
}
```

---

### test_for_update_sql_generated

select_for_update가 호출될 때 백엔드의 orm FOR UPDATE이 SQL문으로 알맞게 나타나는지 테스트

```python
@skipUnlessDBFeature('has_select_for_update')
@transaction.atomic
  def test_for_update_sql_generated(self):
      """
      Test that the backend's FOR UPDATE variant appears in
      generated SQL when select_for_update is invoked.
      """
      list(Person.objects.all().select_for_update())
      self.assertTrue(self.has_for_update_sql(connection))# self.assertTrue(True)
```

```sql
INSERT INTO `unit_test_person` (`name`)
VALUES ('Reinhardt')

SELECT `unit_test_person`.`id`,
       `unit_test_person`.`name`
FROM `unit_test_person`
FOR
UPDATE
```

- has_select_for_update
    
    **현재 사용중인 db가** 'SELECT..FOR UPDATE'**를 지원하는지를 확인**
    
    ```python
    def has_for_update_sql(self, tested_connection, nowait=False):
      # Examine the SQL that was executed to determine whether it
      # contains the 'SELECT..FOR UPDATE' stanza.
      for_update_sql = tested_connection.ops.for_update_sql(nowait) # for_update_sql = 'FOR UPDATE', nowait=False
      sql = tested_connection.queries[-1]['sql'] # sql = 'SELECT `unit_test_person`.`id`, `unit_test_person`.`name` FROM `unit_test_person` FOR UPDATE'
      return bool(sql.find(for_update_sql) > -1) # True
    ```
    

---

### test_for_update_sql_generated_nowait

select_for_update가 호출될 때 백엔드의 orm FOR UPDATE NOWAIT이 SQL문으로 알맞게 나타나는지 테스트

```python
@skipUnlessDBFeature('has_select_for_update_nowait')
@transaction.atomic
def test_for_update_sql_generated_nowait(self):
    """
    Test that the backend's FOR UPDATE NOWAIT variant appears in
    generated SQL when select_for_update is invoked.
    """
    list(Person.objects.all().select_for_update(nowait=True))
    self.assertTrue(self.has_for_update_sql(connection, nowait=True))
```

mysql은 for update에 nowait를 지원하지 않기 때문에 skipUnlessDBFeature에서 걸러진다. (postgress에는 있다고 함)

```python
def skipUnlessAnyDBFeature(*features):
    """Skip a test unless a database has any of the named features."""
    return _deferredSkip(
        lambda: not any(getattr(connection.features, feature, False) for feature in features),
        "Database doesn't support any of the feature(s): %s" % ", ".join(features),
        'skipUnlessAnyDBFeature',
    )
```

만약 skipUnlessDBFeature없이 테스트코드가 동작했다면 django.db.utils.NotSupportedError: NOWAIT is not supported on this database backend. 오류가 뜬다

---

### block test

```python
@requires_threading
@skipUnlessDBFeature('has_select_for_update')
@skipUnlessDBFeature('supports_transactions')
def test_block(self):
    """
    Check that a thread running a select_for_update that
    accesses rows being touched by a similar operation
    on another connection blocks correctly.
    """
    # First, let's start the transaction in our thread.
    self.start_blocking_transaction()

    # Now, try it again using the ORM's select_for_update
    # facility. Do this in a separate thread.
    status = []
    thread = threading.Thread( # new connection에 select for update 락만 걸어놓음
        target=self.run_select_for_update, args=(status,)
    )

    # The thread should immediately block, but we'll sleep
    # for a bit to make sure.
    thread.start()
    sanity_count = 0
    while len(status) != 1 and sanity_count < 10:
        sanity_count += 1
        time.sleep(1)
    if sanity_count >= 10:
        raise ValueError('Thread did not run and block')

    # Check the person hasn't been updated. Since this isn't
    # using FOR UPDATE, it won't block.
    p = Person.objects.get(pk=self.person.pk)
    self.assertEqual('Reinhardt', p.name)

    # When we end our blocking transaction, our thread should
    # be able to continue.
    self.end_blocking_transaction()
    thread.join(5.0)

    # Check the thread has finished. Assuming it has, we should
    # find that it has updated the person's name.
    # self.assertFalse(thread.isAlive())
    self.assertFalse(thread.is_alive())

    # We must commit the transaction to ensure that MySQL gets a fresh read,
    # since by default it runs in REPEATABLE READ mode
    transaction.commit()

    p = Person.objects.get(pk=self.person.pk)
    self.assertEqual('Fred', p.name)
```

1. 데코레이터
    - @requires_threading
        
        ```python
        import unittest
        
        # Some tests require threading, which might not be available. So create a
        # skip-test decorator for those test functions.
        try:
            import threading
        except ImportError:
            threading = None
        requires_threading = unittest.skipUnless(threading, 'requires threading')
        
        @requires_threading
        def func:
        	pass
        ```
        
        threading 모듈이 사용 가능한지 확인하는 코드. 만약 모듈을 사용할 수 없는 경우 threading = None이 되고, @requires_threading가 붙은 테스트는 ‘requires threding’이라는 이유로 해당 테스트를 진행하지 않고 건너뛴다.
        
    - @skipUnlessDBFeature: 해당 테스트 진행하는 데이터베이스 엔진이 특정 기능을 지원하는지 확인하는 데코레이터. 만약 지원하지 않는다면 해당 테스트를 건너뛴다
        
        ```python
        from django.test import (TransactionTestCase, skipIfDBFeature,
            skipUnlessDBFeature)
        ```
        
        - @skipUnlessDBFeature('has_select_for_update'): ‘**SELECT ... FOR UPDATE’**
        - @skipUnlessDBFeature('supports_transactions'): transaction

1. start_blocking_transaction
    
    ```python
    def test_block(self):
        # First, let's start the transaction in our thread.
        self.start_blocking_transaction()
    ```
    
    Person 테이블 대상으로 select for update pure sql문을 실행한다. (이후에 동일한 행을 수정하는 select for update 스레드가 블록되는지 확인하기 위해)
    
    이 트랜잭션은 후에 end_blocking_transaction() 메소드가 호출되기 전까지 lock을 유지한다.
    
    ```python
    def start_blocking_transaction(self):
            # Start a blocking transaction. At some point,
            # end_blocking_transaction() should be called.
            self.cursor = self.new_connection.cursor()
            sql = 'SELECT * FROM %(db_table)s %(for_update)s;' % {
                'db_table': Person._meta.db_table,
                'for_update': self.new_connection.ops.for_update_sql(),
            }
            self.cursor.execute(sql, ())
            self.cursor.fetchone()
    ```
    
    ```sql
    System check identified no issues (0 silenced).
    INSERT INTO `unit_test_person` (`name`)
    VALUES ('Reinhardt')
    
    SELECT VERSION(), @@sql_mode, @@default_storage_engine, @@sql_auto_is_null, @@lower_case_table_names,
                                                                                  CONVERT_TZ('2001-01-01 01:00:00', 'UTC', 'UTC') IS NOT NULL
    // unnit test setup 할 때 Person의 첫 번쨰 인스턴스의 이름을 Reinhardt로 생성함
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
    
    SELECT *
    FROM unit_test_person
    FOR
    UPDATE;
    // Person의 모든 인스턴스에 lock
    ```
    

1. run_select_for_update
    
    ```python
    # test_block
    # Now, try it again using the ORM's select_for_update
    # facility. Do this in a separate thread.
    status = []
    thread = threading.Thread( # new connection에 select for update 락만 걸어놓음
        target=self.run_select_for_update, args=(status,)
    )
    ```
    
    모든 Person 인스턴스에 대해 SELECT FOR UPDATE를 실행한 후, select_for_update 이후에 첫 번째 레코드의 이름을 업데이트(Reinhardt →Fred)하려고 시도하고, 저장한 뒤 커밋하는 유틸리티 메서드. 이 함수는 별도의 스레드에서 실행된다.
    
    ```python
    def run_select_for_update(self, status, nowait=False):
            """
            Utility method that runs a SELECT FOR UPDATE against all
            Person instances. After the select_for_update, it attempts
            to update the name of the only record, save, and commit.
    
            This function expects to run in a separate thread.
            """
            status.append('started')
            try:
                with transaction.atomic:
                # We need to enter transaction management again, as this is done on
                # per-thread basis
                    people = list(
                        Person.objects.all().select_for_update(nowait=nowait)
                    )
                    people[0].name = 'Fred'
                    people[0].save()
            except DatabaseError as e:
                status.append(e)
    ```
    
    이어서 스레드가 시작된다. 하지만 이전에 2번에서 이미 start_blocking_transaction에서 Person의 모든 인스턴스에 대해 lock을 걸어놨기 때문에 풀리기 전까지 대기한다.
    
    ```python
    # block_test
    # The thread should immediately block, but we'll sleep
    # for a bit to make sure.
    thread.start()
    sanity_count = 0
    while len(status) != 1 and sanity_count < 10:
        sanity_count += 1
        time.sleep(1)
    if sanity_count >= 10:
        raise ValueError('Thread did not run and block')
    ```
    
    start_blocking_transaction가 정상적으로 실행 됐다면, status = [’started’]일 것이다. 만약 정상적으로 실행 안될 경우를 대비해 최대 10초까지 스레드 실행에 대기를 걸고, 이 이상을 넘는다면 ValueError를 낸다.
    
2. Person의 첫 레코드의 이름이 변했는지 (블락이 된건지) 확인
    
    테스트 시작하고 2번에서 Person의 모든 인스턴스에 대해 lock을 걸고 있으므로 3번의 (Reinhardt →Fred)스레드는 아직도 대기중이다. 따라서 p.name은 Reinhardt여야지 맞다.
    
    ```python
    # test_block
    # Check the person hasn't been updated. Since this isn't
    # using FOR UPDATE, it won't block.
    p = Person.objects.get(pk=self.person.pk)
    self.assertEqual('Reinhardt', p.name)
    ```
    
    ```sql
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    WHERE `unit_test_person`.`id` = 1
    LIMIT 21
    ```
    
    블락이 확인 되었으면 end_blocking_transaction()을 호출하여 2번의 트랜잭션을 close한다
    
    ```python
    # When we end our blocking transaction, our thread should
    # be able to continue.
    self.end_blocking_transaction()
    thread.join(5.0)
    ```
    
    ```python
    def end_blocking_transaction(self):
      # Roll back the blocking transaction.
      self.new_connection.rollback()
    ```
    
3. 블락된 스레드가 실행되는지 확인
    
    ```python
    # Check the thread has finished. Assuming it has, we should
    # find that it has updated the person's name.
    # self.assertFalse(thread.isAlive())
    self.assertFalse(thread.is_alive())
    
    # We must commit the transaction to ensure that MySQL gets a fresh read,
    # since by default it runs in REPEATABLE READ mode
    transaction.commit()
    
    p = Person.objects.get(pk=self.person.pk)
    self.assertEqual('Fred', p.name)
    ```
    
    ```sql
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    FOR
    UPDATE
    
    UPDATE `unit_test_person`
    SET `name` = 'Fred'
    WHERE `unit_test_person`.`id` = 1
    //블락된 스레드 실행됨
    
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    WHERE `unit_test_person`.`id` = 1
    LIMIT 21
    //잘 실행 됐는지 확인
    ```
    

- full sql log
    
    ```sql
    System check identified no issues (0 silenced).
    INSERT INTO `unit_test_person` (`name`)
    VALUES ('Reinhardt')
    
    SELECT VERSION(), @@sql_mode, @@default_storage_engine, @@sql_auto_is_null, @@lower_case_table_names,
                                                                                  CONVERT_TZ('2001-01-01 01:00:00', 'UTC', 'UTC') IS NOT NULL
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
    
    SELECT *
    FROM unit_test_person
    FOR
    UPDATE;
    
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    WHERE `unit_test_person`.`id` = 1
    LIMIT 21
    
    SELECT VERSION(), @@sql_mode, @@default_storage_engine, @@sql_auto_is_null, @@lower_case_table_names,
                                                                                  CONVERT_TZ('2001-01-01 01:00:00', 'UTC', 'UTC') IS NOT NULL
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ
    
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    FOR
    UPDATE
    
    UPDATE `unit_test_person`
    SET `name` = 'Fred'
    WHERE `unit_test_person`.`id` = 1
    
    SELECT `unit_test_person`.`id`,
           `unit_test_person`.`name`
    FROM `unit_test_person`
    WHERE `unit_test_person`.`id` = 1
    LIMIT 21
    ```
    
- 느낀점
    
    꾸준히 보자….그러면 뭐라도 아는게 생긴다….제발 꾸준히 보자