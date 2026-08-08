# financialtr — Kalite Standardı

Bu repoya özgü kurallar. Küresel standartlar `onur-claude-kit` içinde:
`docs/ajan-kalite-standardi.md` (ajan tanımları) ve `docs/hata-kutuphanesi.md`
(gerçekte olmuş hatalar).

`sirket:kalite-denetci` ajanı bu dosyayı okur. Burada yazılı olmayan bir kural
için ajan kural uydurmaz — "yazılı standart yok" diye bulgu yazar.

## Kapı

```bash
./scripts/verify_all.sh
```

Evrensel kontroller: sır sızıntısı · kişisel veri deseni · placeholder kalıntısı ·
karışık alfabe · büyük dosya.

## Repoya özgü kurallar

> Buraya bu repoda geçerli olan kuralları yaz. Örnek başlıklar:
> - Bu repoda neyin commit'lenmemesi gerektiği
> - Teslim öncesi zorunlu kontroller
> - Bilinen tuzaklar (bir kez yaşanmış hatalar)
> - Onay gerektiren işlemler

_Henüz doldurulmadı._

## Bu repoda yaşanmış hatalar

> Bir hata yaşandığında buraya yaz. Yazılmayan hata tekrarlanır.
> Biçim: **Ne oldu** → **Kural** → **Genel ders**

_Henüz kayıt yok._
