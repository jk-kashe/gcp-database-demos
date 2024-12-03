# AlloyDB Vector Search & ScANN Demo

## Prereqs

Deploy and run the Cymbal Air demo as described in [README.md]


## Setting up the database

We will expand the dataset a bit to be able to demonstrate AlloyDB Vector Search

### 1. Downloading demo assets

**Your instructur will provide you with the URL of the demo assets needed for some of the steps**

**Steps**
1. **Connect to the alloydb-client VM.** You can due that either through the Compute Engine screen and SSH to the VM or by using the alloydb-client.sh script.

2. **From the client VM**
```
gsutil cp gs://[bucket_name]/assets.zip assets.zip
unzip assets.zip
```


### 2. Modify Amenities table


The number of rows in the amenities table provided by the Cymbail Air demo is tiny. We will replace that table with a table that has about ~100.000 rows. 

**Steps**
1. **Connect to the alloydb-client VM.** You can due that either through the Compute Engine screen and SSH to the VM or by using the alloydb-client.sh script

2. **From the client VM**
```
  source pgauth.env
  psql -d assistantdemo -f amenities.sql 

```


### 2. Create some demo intents/things users might be looking for

You will notice that we use [AlloyDB AI Embeddings Integration](https://cloud.google.com/alloydb/docs/ai/work-with-embeddings).

**You can use this fact as part of your demo** - showcase how embedding is created automatically for every row!

Note - all required configuration has been provisioned for you by terraform scripts, so you can focus on demoing the functionality :)

You can perform these steps in **AlloyDB Studio**!

```
-- Create the table
CREATE TABLE intent_embedding (
    id SERIAL PRIMARY KEY,
    intent TEXT NOT NULL,
    embedding VECTOR(768) GENERATED ALWAYS AS (embedding('textembedding-gecko@003', intent)::vector) STORED 
);
```

Let's add some questions that airport users might have:

Note: **if you run into issues generating embeddings**, you can 
drop the table and use intent_embedding.sql asset.

```
-- Basic Needs
insert into intent_embedding(intent) values ('Looking for a place to charge my phone');
insert into intent_embedding(intent) values ('Need to fill up my water bottle at a water fountain');
insert into intent_embedding(intent) values ('Where can I find airport Wi-Fi information?');
insert into intent_embedding(intent) values ('Need to use a restroom quickly!');

-- Food and Drink
insert into intent_embedding(intent) values ('Want a quick coffee and a pastry before my flight');
insert into intent_embedding(intent) values ('Looking for a healthy salad or sandwich');
insert into intent_embedding(intent) values ('Where is the nearest bar? Need a drink!');
insert into intent_embedding(intent) values ('Craving some fast food, maybe burgers and fries');
insert into intent_embedding(intent) values ('Want a sit-down restaurant with table service');

-- Relaxation and Comfort
insert into intent_embedding(intent) values ('Looking for a comfortable lounge to relax in');
insert into intent_embedding(intent) values ('Need a place to take a nap or rest');
insert into intent_embedding(intent) values ('Want a massage or spa treatment');

-- Shopping
insert into intent_embedding(intent) values ('Need to buy a last-minute gift or souvenir');
insert into intent_embedding(intent) values ('Looking for a bookstore to browse');
insert into intent_embedding(intent) values ('Want to buy some duty-free items');
insert into intent_embedding(intent) values ('Need to find an electronics store');

-- Services
insert into intent_embedding(intent) values ('Where can I find currency exchange?');
insert into intent_embedding(intent) values ('Need to store my luggage for a few hours');
insert into intent_embedding(intent) values ('Looking for an ATM');
insert into intent_embedding(intent) values ('Where is the airport information desk?');

-- Transportation
insert into intent_embedding(intent) values ('How do I get to the car rental center?');
insert into intent_embedding(intent) values ('Where can I find the taxi stand?');
insert into intent_embedding(intent) values ('Need information about airport shuttle buses');

-- Family Needs
insert into intent_embedding(intent) values ('Looking for a kids play area');
insert into intent_embedding(intent) values ('Where is the baby changing room?');
insert into intent_embedding(intent) values ('Need to find a place to buy baby formula');
```

## Running the Demo

### 1. Querying Amenities

Run this code in AlloyDB Studio or in psql

```
EXPLAIN ANALYZE 
SELECT description
FROM amenities
ORDER BY (embedding <=> (select embedding from intent_embedding ORDER BY RANDOM() LIMIT 1)) asc
limit 5
```

We see that with no index, the whole table is read. Because 100.000 records is still relativelly small, the execution time does not seem terrible at around 150ms on AlloyDB Free Trial instance with 8 VCPUs.

### 2. Simulate multiple users

1. Go to alloydb-client, either by running alloydb-client.sh in cloud shell or through compute/ssh.

2. Run

```
./simulate.sh
```

This script will simulate 100 simultaneous users querying the database and report execution times. With no index, we see something like this:

```
11611.729 ms
11708.217 ms
12033.913 ms
11789.781 ms
11716.809 ms
11590.214 ms
11651.003 ms
11552.739 ms
11515.109 ms
11543.699 ms
11447.900 ms
11568.193 ms
```

This means that each of our 100 users had to wait at least 11 seconds for the answer! Not the user experience we want to provide, and frankly, not the user experience most users would tolerate!

### 3. Let's create ScANN index!

Run this block in AlloyDB Studio or psql

```
CREATE EXTENSION IF NOT EXISTS alloydb_scann;
 CREATE INDEX scann_amenities ON amenities
  USING scann (embedding cosine)
  WITH (num_leaves=100); /*use sqrt(ROWS) as a starting point*/
```


### 4. Let's re-run the single query in AlloyDB Studio

```
EXPLAIN ANALYZE 
SELECT description
FROM amenities
ORDER BY (embedding <=> (select embedding from intent_embedding ORDER BY RANDOM() LIMIT 1)) asc
limit 5
```

The result should be in a a few ms level. That's a hug boost!

### 5. Simulate multiple users

On the alloydb-client vm, run
```
./simulate.sh
```

Some results that we see:

```
2.673 ms
2.842 ms
2.676 ms
2.781 ms
3.874 ms
3.985 ms
2.960 ms
2.760 ms
3.986 ms
3.523 ms
3.999 ms
2.526 ms
```

Explain to your audience the signifficance of this! With ScANN, we reduced the waiting time from 11 **seconds** down to a dew **milliseconds**
