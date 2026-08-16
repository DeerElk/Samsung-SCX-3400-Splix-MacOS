# Драйвер Samsung SCX-3400 Series SpliX для macOS

Неофициальный CUPS-драйвер на основе **SpliX** для принтеров **Samsung SCX-3400 Series** на современных версиях macOS с Apple Silicon.

Драйвер успешно протестирован на **Samsung SCX-3405W**, подключённом по USB.

> 🇬🇧 English version: [README.md](README.md)

## Возможности

Репозиторий содержит:

- протестированный arm64-фильтр CUPS `rastertoqpdl`;
- рабочий PPD для серии SCX-3400;
- исходный код SpliX 2.0.2;
- исходный код JBIG-KIT 2.1;
- скрипты сборки для macOS Apple Silicon;
- скрипт установки с автоматическим обнаружением USB-принтера;
- скрипт удаления драйвера;
- безопасные режимы установки `--dry-run` и `--no-queue`.

## Протестировано

- **Принтер:** Samsung SCX-3405W
- **macOS:** 26.6
- **Архитектура:** Apple Silicon / arm64
- **Подключение:** USB
- **Система печати:** CUPS
- **Драйвер:** SpliX 2.0.2
- **Сжатие:** JBIG-KIT 2.1
- **Язык принтера:** QPDL v3
- **Разрешение:** 600 DPI

При подключении по USB macOS/CUPS определяет принтер как:

```text
Samsung SCX-3400 Series
```

## Быстрая установка

Клонируйте репозиторий:

```bash
git clone https://github.com/DeerElk/Samsung-SCX-3400-Series-SpliX-Driver-macOS.git
cd Samsung-SCX-3400-Series-SpliX-Driver-macOS
```

Подключите принтер по USB и запустите:

```bash
./scripts/install.sh
```

Установщик автоматически определит USB-принтер Samsung SCX-3400, который видит macOS, и создаст очередь CUPS с использованием PPD из репозитория.

### Предварительный просмотр установки

Чтобы посмотреть, какие действия будут выполнены, ничего не изменяя в системе:

```bash
./scripts/install.sh --dry-run
```

### Установка только драйвера

Чтобы установить фильтр и PPD, но не создавать и не изменять очередь CUPS:

```bash
./scripts/install.sh --no-queue
```

Оба режима можно использовать одновременно:

```bash
./scripts/install.sh --dry-run --no-queue
```

## Если принтер не подключён

Установщик всё равно установит драйвер и PPD.

После подключения принтера проверьте, обнаруживает ли его macOS:

```bash
lpinfo -v | grep -i SCX-3400
```

При нормальном подключении USB результат будет примерно таким:

```text
direct usb://Samsung/SCX-3400%20Series?serial=XXXXXXXX
```

После этого очередь можно создать вручную:

```bash
sudo lpadmin   -p Samsung_SCX_3400_Series   -E   -v 'URI_ПРИНТЕРА_ИЗ_ПРЕДЫДУЩЕЙ_КОМАНДЫ'   -P ./driver/scx3400.ppd
```

## Проверка печати

Сделать принтером по умолчанию:

```bash
lpoptions -d Samsung_SCX_3400_Series
```

Напечатать PDF:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.pdf
```

или изображение:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.jpg
```

Проверить состояние принтера:

```bash
lpstat -p
lpstat -v
```

## Сборка из исходников

На Mac с Apple Silicon:

```bash
./scripts/build-macos-arm64.sh
```

Скрипт использует исходники SpliX 2.0.2 и JBIG-KIT 2.1, находящиеся в репозитории.

Готовый драйвер находится здесь:

```text
driver/rastertoqpdl
```

После сборки скрипт также проверяет, что полученный файл является Mach-O arm64 и что символы JBIG встроены непосредственно в драйвер.

## Устанавливаемые файлы

Установщик устанавливает:

```text
/usr/libexec/cups/filter/rastertoqpdl
/Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd
```

Очередь CUPS создаётся отдельно с помощью `lpadmin`.

## Удаление

Для удаления установленного драйвера и PPD:

```bash
./scripts/uninstall.sh
```

Если необходимо также удалить очередь принтера:

```bash
sudo lpadmin -x Samsung_SCX_3400_Series
```

Если очередь была создана под другим именем, укажите соответствующее имя.

## Диагностика

### Проверить архитектуру драйвера

```bash
file /usr/libexec/cups/filter/rastertoqpdl
```

Ожидаемый результат:

```text
Mach-O 64-bit executable arm64
```

### Проверить PPD

```bash
ls -l /Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd
```

### Проверить принтер

```bash
lpstat -v
lpstat -p
```

### Проверить обнаружение USB

```bash
lpinfo -v | grep -i SCX-3400
```

### Посмотреть журнал CUPS

```bash
sudo tail -100 /var/log/cups/error_log
```

## Поддерживаемые принтеры

### Проверено

- **Samsung SCX-3405W** — проверен и работает на macOS с Apple Silicon при подключении по USB.

### Модели серии SCX-3400

Драйвер предназначен для семейства принтеров Samsung SCX-3400 Series. Следующие модели относятся к этой серии и потенциально могут использовать совместимое печатное оборудование и протокол:

- Samsung SCX-3400
- Samsung SCX-3400F
- Samsung SCX-3400W
- Samsung SCX-3405
- Samsung SCX-3405F
- Samsung SCX-3405FW
- Samsung SCX-3405W

Также существуют региональные варианты этих моделей:

- SCX-3400/DCS
- SCX-3400/HYP
- SCX-3400A4
- SCX-3400FA4
- SCX-3400/HYPA4
- SCX-3405A4
- SCX-3405FA4
- SCX-3405FWA4
- SCX-3405WA4
- SCX-3405FW/TA4
- SCX-3405FW/TND
- SCX-3405F/EXP
- SCX-3405F/EXPA

> **Важно:** в рамках этого проекта проверена только модель Samsung SCX-3405W. Совместимость с другими моделями серии SCX-3400 пока не подтверждена.

## Благодарности и лицензирование

Проект основан на существующем свободном программном обеспечении, включая:

- **SpliX 2.0.2**
- **JBIG-KIT 2.1**

Исходные компоненты продолжают распространяться на условиях соответствующих им лицензий и с оригинальными уведомлениями об авторских правах.

См.:

- `LICENSE`
- `NOTICE.md`
- `source/splix-2.0.2/`
- `source/jbigkit-2.1/`

для получения полной информации о лицензиях, авторстве и исходном коде.

## Отказ от ответственности

Это неофициальный драйвер, созданный сообществом.

Проект не связан с Samsung, Apple, HP, OpenPrinting или их дочерними компаниями и партнёрами.
