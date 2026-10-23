# Тестовое приложение

Статическая страница на nginx, которая собирается в Docker-образ и
деплоится в Kubernetes Helm-чартом.

## Локальная сборка

```bash
docker build --build-arg APP_VERSION=dev -t diploma-app:dev .
docker run --rm -p 8080:8080 diploma-app:dev
# http://localhost:8080
```

## Публикация

CI делает это автоматически:

- коммит в `main` → образ с тегом `sha-<commit>` и `latest`;
- тег `v*` → образ с версией и деплой в кластер.

Ручная публикация:

```bash
REGISTRY=cr.yandex/crptd2h3nubo1b64a071
docker build -t $REGISTRY/diploma-app:v1.0.0 .
docker push $REGISTRY/diploma-app:v1.0.0
```

## Helm

```bash
helm upgrade --install diploma-app helm/app -n app --create-namespace \
  --set image.tag=v1.0.0 \
  --set imagePullSecrets[0].name=yc-registry \
  --set ingress.host=app.example.com
```

Чарт создаёт Deployment (2 реплики), Service, Ingress, PDB и ServiceAccount.
Контейнер работает от непривилегированного пользователя на порту 8080.
