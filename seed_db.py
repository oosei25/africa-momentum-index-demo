import os
from datetime import datetime, timezone
import psycopg2
from psycopg2.extras import execute_values

HOST = os.getenv("POSTGRES_HOST", "localhost")
PORT = int(os.getenv("POSTGRES_PORT", "6543"))
DB   = os.getenv("POSTGRES_DB", "ami")
USER = os.getenv("POSTGRES_USER", "ami")
PWD  = os.getenv("POSTGRES_PASSWORD", "ami")

countries = [
    ("NG", "Nigeria"),
    ("KE", "Kenya"),
    ("GH", "Ghana"),

]

articles = [
    ("NG","policy","Nigeria announces new tech incentives","https://example.com/ng1","Example","pos",0.7),
    ("KE","success","Kenyan startup secures Series A funding","https://example.com/ke1","Example","pos",0.6),
    ("GH","success","Ghana agri-tech scales to region","https://example.com/gh1","Example","pos",0.55),
]

def main():
    dsn = f"host={HOST} port={PORT} dbname={DB} user={USER} password={PWD}"
    conn = psycopg2.connect(dsn)
    conn.autocommit = False
    try:
        with conn.cursor() as cur:
            # Upsert countries
            cur.execute("SELECT iso2, id FROM countries;")
            rows = cur.fetchall()
            existing = dict(rows) if rows else {}
            for iso2, name in countries:
                if iso2 not in existing:
                    cur.execute(
                        "INSERT INTO countries (iso2, name) VALUES (%s, %s) RETURNING id;",
                        (iso2, name),
                    )
                    cid = cur.fetchone()[0]
                    existing[iso2] = cid

            # Insert sample articles
            now = datetime.now(timezone.utc)
            values = []
            for iso2, sub, title, url, src, lab, score in articles:
                cid = existing.get(iso2)
                values.append((cid, sub, title, url, src, now, lab, score))

            execute_values(
                cur,
                """INSERT INTO articles
                    (country_id, sub_indicator, title, url, source_name, published_at, sentiment_label, sentiment_score)
                        VALUES %s ON CONFLICT DO NOTHING""", values,

            )
        conn.commit()
        print("✅ Seed complete.")
    except Exception as e:
        conn.rollback()
        print("❌ Error:", e)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
