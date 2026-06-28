# 싱글턴 패턴 - Streak 모델 적용

| 항목 | 내용 |
| --- | --- |
| 분류 | 디자인 패턴 > 생성 패턴(Creational Pattern) |
| 맥락 | Streak 모델 구현 시 싱글턴 패턴 적용 |

---

## 디자인 패턴이란?

소프트웨어 설계에서 자주 반복되는 문제를 해결하는 **정형화된 방법론**. GoF(Gang of Four) 책에서 23가지 패턴을 체계화했고, 크게 세 분류로 나뉜다:

- **생성 패턴(Creational)** — 객체를 어떻게 만들 것인가 (싱글턴, 멀티턴, 팩토리 등)
- **구조 패턴(Structural)** — 객체를 어떻게 조합할 것인가 (어댑터, 데코레이터 등)
- **행위 패턴(Behavioral)** — 객체 간 책임을 어떻게 분배할 것인가 (옵저버, 전략 등)

---

## 싱글턴(Singleton)

인스턴스가 **딱 하나만** 존재하도록 보장하는 패턴.

### LearnLog에서의 적용

```python
class Streak(models.Model):
    @classmethod
    def load(cls):
        obj, _ = cls.objects.get_or_create(pk=1)  # 항상 pk=1 하나만
        return obj
```

이 앱은 사용자 구분 없이 혼자 쓰므로, Streak 테이블에 행이 하나만 있으면 충분하다. `get_or_create(pk=1)`로 항상 같은 레코드를 반환한다. Streak 시스템의 전체 구현은 → [[통계 대시보드 + Streak(불꽃) 시스템 구현]]

### 싱글턴이 적합한 경우
- 전역 설정, 앱 설정
- 단일 사용자 앱의 상태 관리
- DB 커넥션 풀, 로거 등 하나만 있어야 하는 자원

---

## 멀티턴(Multiton)

**키별로 인스턴스를 하나씩** 관리하는 패턴. 싱글턴의 확장판.

### 예시: 다중 사용자 Streak

```python
class Streak(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)

    @classmethod
    def load(cls, user):
        obj, _ = cls.objects.get_or_create(user=user)  # 유저별로 하나씩
        return obj
```

나중에 다중 사용자를 지원하게 되면 싱글턴 → 멀티턴으로 전환하면 된다.

---

## 비교

| | 싱글턴 | 멀티턴 | 일반 모델 |
| --- | --- | --- | --- |
| 인스턴스 수 | 전체에서 1개 | 키당 1개 | 제한 없음 |
| 예시 | Streak(단일 사용자) | Streak(유저별) | LearningLog(질문마다 생성) |
| 제약 | pk=1 고정 | unique 키 (user FK 등) | 없음 |
