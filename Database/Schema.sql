CREATE TABLE "predictions" (
   "id" bigserial PRIMARY KEY NOT NULL,
	"sender_id" text NOT NULL,
   "transaction_id" text NOT NULL,
   "price" decimal(13, 4) NOT NULL, -- Comply with GAAP (http://www.fasab.gov/accounting-standards/)
	"created_at" timestamp NOT NULL,
   "ip" text NOT NULL
);

CREATE TABLE "prices" (
	"price" decimal(16, 8) NOT NULL, -- Lisk price in satoshi
   "btc" decimal(16, 8) NOT NULL, -- Bitcoin price in USD
	"updated_at" timestamp NOT NULL
);
