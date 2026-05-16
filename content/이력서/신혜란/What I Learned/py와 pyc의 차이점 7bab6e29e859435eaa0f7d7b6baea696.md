# .py와 .pyc의 차이점

Status: python

아래 글을 정리한 내용입니다.

[Understanding the use of Python bytecode files in different scenarios.](https://medium.com/@vuducly151092/understanding-the-use-of-python-bytecode-files-in-different-scenarios-1ffd39723908)

![](py%EC%99%80%20pyc%EC%9D%98%20%EC%B0%A8%EC%9D%B4%EC%A0%90/Untitled.png)

- python은 모듈의 소스코드(.py)를 처음 가져올 때, 바이트 코드를 생성하여(.pyc) 모듈 로딩 성능을 향상시킨다.
- 파이썬은 기존의 바이트 코드 파일(.pyc)을 사용할 것인지, 소스 코드 파일(.py)을 다시 컴파일 할 것인지를 결정하는 몇 가지 시나리오가 있다.

1. 빈 폴더에 python 소스코드 파일을 생성한다.
    
    ```bash
    ~/Desktop/인터파크/sql_practice/pyc_study 33s
    .venv ❯ ls
    hello_world.py
    ```
    
2. 생성한 소스 코드를 최초로 임포트 한다.
    
    ```bash
    ~/Desktop/인터파크/sql_practice/pyc_study
    .venv ❯ python3
    Python 3.9.2 (default, Mar 25 2021, 03:27:19) 
    [Clang 11.0.0 (clang-1100.0.33.17)] on darwin
    Type "help", "copyright", "credits" or "license" for more information.
    >>> import hello_world
    hello world!
    >>> exit()
    ```
    
3. 같은 위치에 __pycache__ 폴더가 생겼고, 안에는 .pyc파일이 생겼다.
    
    ```bash
    ~/Desktop/인터파크/sql_practice/pyc_study 1m 20s
    .venv ❯ ls -a
    .              ..             __pycache__    hello_world.py
    
    .venv ❯ ls __pycache__
    hello_world.cpython-39.pyc
    
    .venv ❯ cat ./__pycache__/hello_world.cpython-39.pyc
    a
    @�d�@s
          ed�dS)z
                 hello world!N)�print�rr�[/Users/shinhaeran/Desktop/인터파크/sql_practice/pyc_study/hello_world.py<module>�
    ```
    
4. .py파일의 변화
    1. 만약 .pyc는 남겨놓고, .py를 지운다면 어떻게 될까?: **안된다!**  No module named 'hello_world'
        
        ```bash
        .venv ❯ rm hello_world.py
        
        ~/Desktop/인터파크/sql_practice/pyc_study
        .venv ❯ python3
        Python 3.9.2 (default, Mar 25 2021, 03:27:19) 
        [Clang 11.0.0 (clang-1100.0.33.17)] on darwin
        Type "help", "copyright", "credits" or "license" for more information.
        >>> import hello_world.py
        Traceback (most recent call last):
          File "<stdin>", line 1, in <module>
        ModuleNotFoundError: No module named 'hello_world'
        ```
        
    2. 다시 ‘hello_world.py’ 파일은 복구하되, 변화가 있다면?: 실행은 무사히 되지만, .pyc 파일도 변경된다.
        
        ```bash
        ~/Desktop/인터파크/sql_practice/pyc_study 18s
        .venv ❯ python3
        Python 3.9.2 (default, Mar 25 2021, 03:27:19) 
        [Clang 11.0.0 (clang-1100.0.33.17)] on darwin
        Type "help", "copyright", "credits" or "license" for more information.
        >>> import hello_world
        changed hello world!
        >>> exit()
        
        ~/Desktop/인터파크/sql_practice/pyc_study 10s
        .venv ❯ ls -al __pycache__
        total 8
        drwxr-xr-x  3 shinhaeran  staff   96  3 15 01:10 .
        drwxr-xr-x  4 shinhaeran  staff  128  3 15 01:10 ..
        -rw-r--r--  1 shinhaeran  staff  219  3 15 01:10 hello_world.cpython-39.pyc
        ```
        
    
    5. .py파일을 import말고, 바로 실행한다면?: .pyc파일이 생성되지 않는다.
    
    ```bash
    ~/Desktop/인터파크/sql_practice/pyc_study
    .venv ❯ rm -r __pycache__
    
    ~/Desktop/인터파크/sql_practice/pyc_study
    .venv ❯ ls -al
    total 8
    drwxr-xr-x  3 shinhaeran  staff   96  3 15 01:17 .
    drwxr-xr-x  5 shinhaeran  staff  160  3 15 00:59 ..
    -rw-r--r--  1 shinhaeran  staff   30  3 15 01:10 hello_world.py
    
    ~/Desktop/인터파크/sql_practice/pyc_study
    .venv ❯ python3 hello_world.py
    changed hello world!
    
    ~/Desktop/인터파크/sql_practice/pyc_study
    .venv ❯ ls -al
    total 8
    drwxr-xr-x  3 shinhaeran  staff   96  3 15 01:17 .
    drwxr-xr-x  5 shinhaeran  staff  160  3 15 00:59 ..
    -rw-r--r--  1 shinhaeran  staff   30  3 15 01:10 hello_world.py
    ```
    

## 💡 결론

- 파이썬은 모듈을 로딩하기 위해 파이썬 파일과 해당 바이트 코드 파일을 확인한다.
- 모듈이 삭제되면, 파이썬은 기존의 바이트 코드를 사용하지 않고, 소스 파일이 없다는 오류를 발생시킨다.
- 모듈이 업데이트되면서 기존의 바이트 코드가 오래된 경우, 파이썬은 모듈을 다시 컴파일하고 새로운 바이트 코드로 교체한다.