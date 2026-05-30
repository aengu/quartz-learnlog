---
title: "Django DB Connection"
---

# Django DB Connection

Status: django

Django의 데이터베이스와 연결된 프로세스는 요청을 받은 후 최초 데이터베이스에 접속할 때, connection이 생성되고 연결이 종료될 때까지 유지됩니다.

### django에서 connection의 수명주기

1. request 생성
    
    ```python
    # django.db.__init__.py
    
    # For backwards compatibility. Prefer connections['default'] instead.
    connection = DefaultConnectionProxy()
    
    # Register an event to reset saved queries when a Django request is started.
    def reset_queries(**kwargs):
        for conn in connections.all():
            conn.queries_log.clear()
    
    signals.request_started.connect(reset_queries)
    
    # Register an event to reset transaction state and close connections past
    # their lifetime.
    def close_old_connections(**kwargs):
        for conn in connections.all():
            conn.close_if_unusable_or_obsolete()
    
    signals.request_started.connect(close_old_connections)
    signals.request_finished.connect(close_old_connections)
    ```
    
    - request가 시작될 때 쿼리 로그를 초기화 하고, 오래된 연결을 닫습니다.
    - request가 종료될 때 오래된 연결을 닫습니다.
2. connection 생성
    
    ```python
    # django.db.backends.base
    class BaseDatabaseWrapper:
        """Represent a database connection."""
        def __init__(self, settings_dict, alias=DEFAULT_DB_ALIAS):
            self.settings_dict = settings_dict
            self.close_at = None
    
        def connect(self):
            max_age = self.settings_dict['CONN_MAX_AGE']
            self.close_at = None if max_age is None else time.monotonic() + max_age
    ```
    
    - 연결 종료 시각을 CONN_MAX_AGE가 None으로 설정되어 있다면 None, 그렇지 않은 경우 [생성시점 + CONN_MAX_AGE]로 정의합니다.
    - CONN_MAX_AGE의 경우 기본값은 0이며, request가 종료되는 순간 바로 연결이 종료됩니다.
    - None으로 설정된다면, 연결이 무제한으로 유지됩니다.
    - CONN_MAX_AGE 설정
        
        ```python
        # settings.py
        DATABASES = {
            'order': {
                'ENGINE': 'django.db.backends.mysql',
                'HOST': '',
                'PORT': '',
                'NAME': '',
                'USER': '',
                'PASSWORD': '',
        				'CONN_MAX_AGE': 0, # default
            },
        }
        ```
        
    
3. request 종료와 connection 종료
    
    ```python
    # django.db.__init__.py
    
    # Register an event to reset transaction state and close connections past
    # their lifetime.
    def close_old_connections(**kwargs):
        for conn in connections.all():
            conn.close_if_unusable_or_obsolete()
    
    signals.request_started.connect(close_old_connections)
    signals.request_finished.connect(close_old_connections)
    
    # django.db.backends.base.base.py
    def close_if_unusable_or_obsolete(self):
    	  """
    	  Close the current connection if unrecoverable errors have occurred
    	  or if it outlived its maximum age.
    	  """
    	  if self.connection is not None:
    	      # If the application didn't restore the original autocommit setting,
    	      # don't take chances, drop the connection.
    	      if self.get_autocommit() != self.settings_dict['AUTOCOMMIT']:
    	          self.close()
    	          return
    	
    	      # If an exception other than DataError or IntegrityError occurred
    	      # since the last commit / rollback, check if the connection works.
    	      if self.errors_occurred:
    	          if self.is_usable():
    	              self.errors_occurred = False
    	          else:
    	              self.close()
    	              return
    	
    	      if self.close_at is not None and time.monotonic() >= self.close_at:
    	          self.close()
    	          return
    ```
    
    - request가 시작/종료될 때, 호출되어 현재 데이터베이스 연결을 더이상 사용할 수 없거나, 최대 수명을 넘은 경우 종료합니다.
    - connection 생성 때 설정한 close_at과 현재 시간을 비교하여 connection의 유지 여부를 검사하여 close_at이 큰 경우(최대 수명을 넘은 경우) 종료합니다.

### 주의사항

단, 유의할 점은 `CONN_MAX_AGE`는 **요청에 대한 connection** **close** **시간**을 설정하는 것입니다. ORM 쿼리를 실행할 때 맺은 connection에는 영향을 주지 못합니다. 따라서 API 호출이 아닌 배치등의 로직으로 맺어진 connection은 관리가 되지 않을 수 있습니다.

- APScheduler
    
    ![Untitled](attachments/Django%20DB%20Connection_Untitled.png)
    
    ```python
    time.monotonic()
    205281.265
    db.connections['order'].close_at
    205043.296
    # 현재 시간이 db connection의 close_at을 지났음에도 connection이 유지되어 있음
    ```
    
    Thread를 사용하는 경우,  Thread를 실행시킨 메인 프로세스, 즉 APScheduler 프로세스가 종료될 때 connection이 닫히게 됩니다. APScheduler는 각 schedule task마다 ThreadPollExecutor-1_n 이름의 프로세스를 생성하는데, 이 경우 Thread가 job실행 시간이 아님에도 비활성되지 않아 Connection이 닫히지 않습니다. 때문에 해당 thread의 db connection이 도중에 'lost connection' 'mysql server gone'같은 오류가 난 경우, 해당 오류가 발생한 connection이 유지되어 오류가 해결 되었어도 여전히 exception이 발생할 수 있습니다. 마지막에는 명시적으로 모든 connection을 close하는 것이 좋습니다.
    
- 명시적으로 connection close하기
    
    ```python
    def OrderTransaction():
        try:
            with transaction.atomic():
        except:
            order_logger.send_log('')
            db.connections['order'].close_if_unusable_or_obsolete()
    ```