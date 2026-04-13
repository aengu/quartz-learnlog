# 검색 중 프로그레스바 + 진행로그를 위한 SSE 구현

[https://github.com/aengu/learn-log/commit/09bca5169f4d38256e33e6e36c993e54d6589363](https://github.com/aengu/learn-log/commit/09bca5169f4d38256e33e6e36c993e54d6589363)

AI 질문 처리 시 사용자에게 실시간 진행 상황을 보여주기 위해 SSE 구현.

| 항목 | 내용 |
| --- | --- |
| 목적 | 처리 단계별 프로그레스 바 + 메시지 표시 |
| 방식 | Server-Sent Events (단방향 스트리밍) |

---

## 구조

```
[브라우저] ──POST──▶ [QuerySSEView]
											│
◀─── event: progress ─┤ (1/5 질문 받음)
◀─── event: progress ─┤ (2/5 검색 완료)
◀─── event: progress ─┤ (3/5 AI 답변 생성)
◀─── event: progress ─┤ (4/5 태그 추출)
◀─── event: progress ─┤ (5/5 마크다운 변환)
◀─── event: complete ─┘ (최종 result.html 마크다운 렌더링)
```

---

### 1. 백엔드 (Django)

```python
# views.py
@method_decorator(csrf_exempt, name='dispatch')
class QuerySSEView(View):
    def post(self, request):
        query = request.POST.get('query', '').strip()
        return StreamingHttpResponse(
            self._process_stream(query),
            content_type='text/event-stream'
        )

    def _process_stream(self, query):
        """제너레이터 - yield마다 클라이언트에 전송"""
        service = LearnlogService()

        yield self._sse_event('progress', {'step': 1, 'total': 5, 'message': '질문 받음'})

        search_results = service.search_official_docs(query)
        yield self._sse_event('progress', {'step': 2, 'total': 5, 'message': '검색 완료'})

        ai_answer = service.generate_answer(query, search_results)
        yield self._sse_event('progress', {'step': 3, 'total': 5, 'message': 'AI 답변 생성'})

        # ... 나머지 단계 ...

        yield self._sse_event('complete', {'html': result_html})

    def _sse_event(self, event_type, data):
        """SSE 표준 포맷"""
        return f"event: {event_type}\\ndata: {json.dumps(data, ensure_ascii=False)}\\n\\n"

```

**핵심 포인트:**

- `StreamingHttpResponse`: 응답을 한 번에 보내지 않고 스트리밍
- `yield`: 각 단계 완료 시 즉시 클라이언트에 전송
- 서비스 메서드 개별 호출: `process_query()` 하나로 묶으면 중간 yield 불가

### **2. 프론트엔드 (JavaScript)**

```javascript
fetch('{% url "search:query_api_stream" %}', {
    method: 'POST',
    body: formData,
}).then(response => {
    const reader = response.body.getReader();
    const decoder = new TextDecoder();

    function processStream() {
        reader.read().then(({ done, value }) => {
            if (done) {return;}
						// SSE 이벤트 파싱
            for (const line of lines) {
                if (line.startsWith('event:')) {
                    const eventType = line.slice(7).trim();
                    continue;
                }
                if (line.startsWith('data:')) {
                    const data = JSON.parse(line.slice(5).trim());

                    if (data.step !== undefined) {
                        // progress 이벤트
                        progressBar.value = data.step;
                        progressMessage.textContent = data.message;
                    } else if (data.html !== undefined) {
                        // complete 또는 error 이벤트
                        progressContainer.classList.add('hidden');
                        resultContainer.innerHTML = data.html;
                    }
                }
            }
            processStream(); // 재귀 호출
        });
    }
    processStream();
});
```

**HTMX 대신 fetch 사용 이유:**

- HTMX의 SSE 지원이 제한적
    
    ### **HTMX의 SSE 지원 방식**
    
    [https://htmx.org/extensions/sse/](https://htmx.org/extensions/sse/)
    
    HTMX는 `hx-ext="sse"` 확장으로 SSE 지원함:
    
    ```html
    <div hx-ext="sse" sse-connect="/stream" sse-swap="message">
        <!-- 메시지 올 때마다 여기 교체 -->
    </div>
    ```
    
    ### **문제점**
    
    **1. 이벤트 타입 구분이 어려움**
    
    우리는 `progress`, `complete`, `error` 세 가지 이벤트가 필요한데
    
    ```
    event: progress   ← 프로그레스 바 업데이트
    data: {"step": 2}
    
    event: complete   ← 최종 결과 HTML 삽입
    data: {"html": "..."}
    ```
    
    HTMX SSE는 기본적으로 **하나의 타겟에 교체**하는 방식이라, 이벤트 타입별로 다른 동작(프로그레스 바 vs 결과 컨테이너) 처리가 복잡함.
    
    **2. JSON 파싱 + 로직 처리 어려움**
    
    ```javascript
    // fetch는 이렇게 자유롭게 처리 가능
    if (data.step !== undefined) {
        progressBar.value = data.step;  // 숫자 업데이트
        progressMessage.textContent = data.message;  // 텍스트 업데이트
    }
    ```
    
    HTMX는 받은 데이터를 **그대로 HTML로 swap**하는 게 기본이라, JSON 파싱 후 여러 요소 업데이트가 번거로움.
    
    **3. 스트림 중간 처리**
    
    ```javascript
    // fetch + ReadableStream
    reader.read().then(({ done, value }) => {
        // 청크 올 때마다 즉시 처리
        buffer += decoder.decode(value);
        // 파싱...
    });
    ```
    
    HTMX는 이런 저수준 스트림 제어가 안 됨. 이벤트 단위로만 받음.
    
- readable stream?
    
    브라우저에서 **데이터를 조금씩 읽을 수 있게** 해주는 Web API
    
    **일반 fetch:**
    
    ```javascript
    const response = await fetch('/api');
    const data = await response.json();  // 전체 다 받을 때까지 대기
    ```
    
    → 10MB 파일이면 10MB 다 받아야 사용 가능
    
    **ReadableStream:**
    
    ```javascript
    const response = await fetch('/api');
    const reader = response.body.getReader();  // ← 이게 ReadableStream
    
    while (true) {
        const { done, value } = await reader.read();  // 조금씩 읽음
        // value: 도착한 청크 (일부분)
        if (done) break;
    }
    ```
    
    → 데이터 **도착하는 대로** 바로바로 처리
    
    ### **SSE에서 왜 필요?**
    
    ```
    서버: "event: progress\ndata: {step: 1}\n\n"  ──▶ 바로 처리!
    서버: "event: progress\ndata: {step: 2}\n\n"  ──▶ 바로 처리!
    서버: "event: complete\ndata: {html: ...}\n\n" ──▶ 바로 처리!
    ```
    
    SSE는 서버가 **여러 번 나눠서** 보내니까, ReadableStream으로 **도착할 때마다** 읽어서 프로그레스 바 업데이트할 수 있음.
    
    일반 fetch로 하면 complete 이벤트까지 전부 다 받은 후에야 처리할 수 있어서 프로그레스 바가 의미 없어짐.
    

---

## **SSE 이벤트 포맷**

```
event: progress
data: {"step": 2, "total": 5, "message": "검색 완료: 5개 결과"}

event: complete
data: {"html": "<div class='card'>...</div>"}

event: error
data: {"html": "<div class='alert alert-error'>...</div>"}
```

---

## **현재 한계: 동기 처리**

### **문제점**

현재는 **동기(Synchronous)** 방식:

```python
search_results = service.search()  # 블로킹 - 3초 대기
ai_answer = service.generate()     # 블로킹 - 5초 대기
```

ex) 

요청 하나가 워커 스레드 하나를 **10초간 점유** (Django는 워커(스레드/프로세스)가 제한적임. 기본값: 4개)

```
워커1: 사용자A (10초 점유)
워커2: 사용자B (10초 점유)
워커3: 사용자C (10초 점유)
워커4: 사용자D (10초 점유)
사용자E: 대기..
```

---

## **향후 개선: 비동기 전환**

### **비동기(Async) 방식**

I/O 대기 시간(API 호출, DB 쿼리) 동안 다른 요청 처리 가능.

```python
async def _process_stream(self, query):
    result = await asyncio.to_thread(service.search)  # 대기 중 다른 요청 처리
    yield ...
```

---

파일구조

```
search/
├── views.py          # QuerySSEView 추가
├── urls.py           # /api/query/stream/ 라우트 추가
└── services.py       # save_learning_log() 분리

templates/search/
└── main.html         # SSE fetch + 프로그레스 바 UI
```