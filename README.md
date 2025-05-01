# Apache Kafka Developer Hands-On Guide

Dokumentasi ini mencakup langkah-langkah praktikum (hands-on labs) dari pelatihan **Apache Kafka Developer** berdasarkan modul dari CNFLTraining dan Confluent Platform.

---

## 🧰 Prasyarat

- Docker dan Docker Compose terinstal
- Akun Docker Hub (untuk login dan push image)
- Akses ke jaringan yang stabil
- Linux (Ubuntu VM atau baremetal)

---

## 📦 Daftar Lab

### ✅ Lab 1: Start the Kafka Environment
**Tujuan:** Memulai semua layanan Kafka dengan Docker Compose.

**Langkah:**
```bash
docker-compose up -d
```
**Layanan yang berjalan:**
- Zookeeper
- Kafka Broker
- Schema Registry
- KSQLDB Server
- Connect
- Control Center

---

### ✅ Lab 2: Create Topics and Publish Data
**Tujuan:** Membuat topik dan publish data dengan Kafka CLI.

**Langkah:**
```bash
docker exec -it kafka kafka-topics --create   --bootstrap-server kafka:9092 --replication-factor 1   --partitions 3 --topic driver-positions

kafka-console-producer   --bootstrap-server kafka:9092 --topic driver-positions
```

---

### ✅ Lab 3: Consume from Topics
**Tujuan:** Mengkonsumsi data dari topik yang dibuat.

**Langkah:**
```bash
kafka-console-consumer   --bootstrap-server kafka:9092 --topic driver-positions   --from-beginning
```

---

### ✅ Lab 4: Use Avro and Schema Registry
**Tujuan:** Publish dan consume data menggunakan Avro format.

**Langkah:**
```bash
kafka-avro-console-producer   --broker-list kafka:9092 --topic driver-profiles-avro   --property value.schema='{"type":"record","name":"Driver","fields":[{"name":"driver_id","type":"string"}]}'
```

---

### ✅ Lab 5: Enrich Data Using KSQLDB
**Tujuan:** Membuat stream dan join antar stream di KSQLDB.

**Langkah:**
```sql
CREATE STREAM driver_positions WITH (KAFKA_TOPIC='driver-positions', VALUE_FORMAT='JSON');
CREATE STREAM driver_profiles WITH (KAFKA_TOPIC='driver-profiles-avro', VALUE_FORMAT='AVRO');

CREATE STREAM driver_enriched AS
SELECT p.driver_id, p.lat, p.lon, pr.name
FROM driver_positions p
LEFT JOIN driver_profiles pr
  ON p.driver_id = pr.driver_id
EMIT CHANGES;
```

---

### ✅ Lab 6: Create and View Tables in KSQLDB
**Tujuan:** Membuat `TABLE` dari Kafka stream dan query dengan semantics KSQL.

**Langkah:**
```sql
CREATE TABLE driver_stats AS
SELECT driver_id, COUNT(*) AS num_records
FROM driver_positions
GROUP BY driver_id
EMIT CHANGES;

SELECT * FROM driver_stats EMIT CHANGES;
```

---

### ✅ Lab 7: Using ksqlDB for Transformations
**Tujuan:** Melakukan manipulasi dan transformasi data menggunakan KSQLDB.

**Langkah:**
```sql
CREATE STREAM transformed AS
SELECT driver_id, UCASE(name) AS upper_name
FROM driver_profiles
EMIT CHANGES;
```

---

### ✅ Lab 8: Avro Schemas and Schema Evolution
**Tujuan:** Uji pengaruh perubahan skema pada data.

**Langkah:**
- Buat schema awal
- Kirim data
- Ubah schema (misal tambah field optional)
- Kirim lagi
- Pastikan compatible

---

### ✅ Lab 9: Joins in ksqlDB
**Tujuan:** Gabungkan dua stream di ksqlDB dengan waktu bergeser.

**Langkah:**
```sql
CREATE STREAM joined_stream AS
SELECT p.driver_id, p.lat, pr.name
FROM driver_positions p
INNER JOIN driver_profiles pr
WITHIN 5 MINUTES
  ON p.driver_id = pr.driver_id
EMIT CHANGES;
```

---

### ✅ Lab 10: Monitor with Control Center
**Tujuan:** Gunakan Control Center untuk memonitor topik dan consumer.

**Langkah:**
- Akses: http://localhost:9021
- Pilih topik → monitoring offset, lag, throughput

---

### ✅ Lab 11: Kafka Connect JDBC Source
**Tujuan:** Menarik data dari PostgreSQL dan publish ke Kafka menggunakan JDBC Source Connector.

**Langkah:**
```bash
docker exec -it -u root connect bash
confluent-hub install confluentinc/kafka-connect-jdbc:10.0.0
docker-compose restart connect
```

```bash
curl -X POST http://localhost:8083/connectors   -H "Content-Type: application/json"   --data @jdbc-source-avro.json
```

**Catatan:** File `jdbc-source-avro.json` berisi konfigurasi konektor.

---

### ✅ Lab 12: Consumer Offset Management
**Tujuan:** Mulai konsumsi data Kafka dari waktu tertentu (mis. 5 menit lalu).

**Langkah:**
- Gunakan `offsetsForTimes()` untuk mendapatkan offset berdasarkan timestamp.
- Lakukan `seek()` ke offset tersebut:

```java
long startTime = System.currentTimeMillis() - Duration.ofMinutes(5).toMillis();
// kemudian mapping TopicPartition dan offset
```

**Perbandingan:**
- `seekToBeginning()` = konsumsi dari awal
- `seek(offset)` = konsumsi dari waktu spesifik

---

### ✅ Lab 13: Partitioning Considerations
**Tujuan:** Memahami bagaimana key dipetakan ke partisi dan efek penambahan partisi.

**Langkah:**
```bash
docker exec -it tools bash
kafkacat -b kafka:9092 -t driver-positions-avro -Ceq -f 'Key: %k Partition: %p\n' | sort | uniq
```

**Tambah partisi:**
```bash
docker exec -it kafka kafka-topics   --bootstrap-server kafka:9092   --alter --topic driver-positions-avro   --partitions 10
```

**Analisis:** Lihat apakah key masuk ke partisi berbeda sebelum dan sesudah resize.

---

### ✅ Lab 14: Stream Enrichment
**Tujuan:** Gabungkan dua stream menjadi satu enriched stream menggunakan `ksqlDB`.

**Langkah:**
```sql
CREATE STREAM enriched AS
SELECT a.*, b.make FROM driver_positions a
LEFT JOIN driver_profiles b ON a.driver_id = b.driver_id
EMIT CHANGES;
```

**Verifikasi:** Cek hasil `SELECT * FROM enriched EMIT CHANGES;`

---

### ✅ Lab 15: Kafka Sink Connector
**Tujuan:** Kirim data dari Kafka ke PostgreSQL.

**Langkah:**
```bash
curl -X POST http://localhost:8083/connectors   -H "Content-Type: application/json"   --data @jdbc-sink.json
```

**Catatan:**
- Data masuk ke PostgreSQL dalam tabel `driver_positions_sink`
- Pastikan JDBC Sink Connector sudah berhasil `connect` dan `RUNNING`

---

## 🐳 Push Docker Image ke Docker Hub
**Langkah-langkah:**
```bash
docker login

docker tag cnfltraining/node-webserver-avro:2.0 itasoftdidit/node-webserver-avro:2.0
docker push itasoftdidit/node-webserver-avro:2.0
# ulangi untuk semua image lainnya
```

**Skrip otomatis:**
```bash
chmod +x push-all.sh
./push-all.sh
```

---

## 📁 Struktur Folder
```
confluent-dev/
├── docker-compose.yml
├── postgres/
│   └── docker-entrypoint-initdb.d/init.sql
├── challenge/
│   └── java-consumer-prev/
│       └── Consumer.java
├── solution/
│   └── java-producer/
│       └── Producer.java
├── tools/
└── webserver-avro/
```

---

## 🔗 Referensi
- https://docs.confluent.io/
- https://docs.confluent.io/kafka-connect-jdbc/current/index.html
- https://ksqldb.io/

---

> Guide ini bisa langsung digunakan sebagai README.md untuk dokumentasi Kafka hands-on. Tambahkan file konfigurasi seperti .json, .sql, dan docker-compose.yml untuk pelengkap lab per folder.
