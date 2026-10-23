# Разделение на отдельные репозитории

По ТЗ удобно иметь три репозитория. Текущий монорепозиторий уже разделён по
директориям, поэтому вынос делается копированием:

```bash
# infra
mkdir -p ../diploma-infra && cp -R infra/* ../diploma-infra/
# app
mkdir -p ../diploma-app && cp -R app/* ../diploma-app/
# k8s
mkdir -p ../diploma-k8s && cp -R k8s/* ../diploma-k8s/
```

Что перенести вместе с директориями:

- `diploma-infra`: `.github/workflows/terraform.yml` (заменить `working-directory`
  на `.`), `docs/`;
- `diploma-app`: `.github/workflows/app.yml` (убрать `app/` из путей,
  `CHART_PATH: helm/app`);
- `diploma-k8s`: `README.md` и `manifests/`.

После разделения в каждом репозитории сделать `git init`, первый коммит и
`git remote add origin ...`. Ссылки на все три добавить в корневой README
(пункт 7 чек-листа).
