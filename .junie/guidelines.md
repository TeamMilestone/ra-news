# 프로젝트 가이드라인

이 프로젝트는 Ruby, Rails 8, Tailwind CSS를 기반으로 개발되었습니다. 아래는 Junie 및 개발자들이 참고해야 할 주요 가이드라인입니다.

## 프로젝트 구조
- `app/`: Rails 표준 구조 (models, controllers, views, jobs, mailers 등)
- `app/javascript/`: Hotwire(Turbo, Stimulus) 관련 JS 코드
- `app/assets/`: 빌드된 이미지, 스타일시트, Tailwind 설정 등
- `config/`: 환경설정, 라우팅, 이니셜라이저 등
- `test/`: Rails 기본 테스트 구조

## 테스트 및 빌드
- PR 또는 주요 변경 시 반드시 테스트를 실행하세요: `bin/rails test`
- 커스텀 빌드/테스트가 필요할 경우, 별도 스크립트나 README에 명시하세요.
- CI 환경에서 테스트가 자동 실행되도록 설정되어 있습니다.

## 코드 스타일
- [Ruby Style Guide](https://rubystyle.guide/)를 따르세요.
- 컨트롤러, 모델, 뷰 등은 Rails 공식 가이드에 따라 작성하세요.
- 뷰는 Hotwire(Turbo, Stimulus)와 Tailwind CSS를 적극 활용하세요.
- 중복 코드는 partial, helper, concern 등으로 분리하세요.

## 성능 및 최적화
- DB 인덱싱, eager loading(`includes`), 쿼리 최적화에 신경 쓰세요.
- 캐싱(프래그먼트, 러시안돌 등)을 적극 활용하세요.

## 기타
- 예외 처리는 컨트롤 플로우가 아닌 진짜 예외 상황에만 사용하세요.
- 사용자에게 친절한 에러 메시지와 flash 메시지를 제공하세요.
- Junie가 자동화 작업(테스트, 빌드 등)을 수행할 때는 위 가이드라인을 참고하세요.
