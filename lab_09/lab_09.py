import os
import time

import matplotlib.pyplot as plt
import psycopg2
import redis


class PerformanceAnalyzer:
    def __init__(self):
        # PostgreSQL connection
        self.pg_conn = psycopg2.connect(
            dbname=os.getenv("DB_NAME", "postgres"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD"),
            host=os.getenv("DB_HOST", "localhost"),
            port=os.getenv("DB_PORT", 5432)
        )

        # Redis connection
        self.redis_client = redis.Redis(
            host=os.getenv("REDIS_HOST", "localhost"),
            port=int(os.getenv("REDIS_PORT", 6379)),
            db=int(os.getenv("REDIS_DB", 0))
        )

        self.stats_query = """
            SELECT r.room_id, r.name, COUNT(rir.rehearsal_id) as usage_count
            FROM room r
            LEFT JOIN rehearsals_in_room rir ON r.room_id = rir.room_id
            GROUP BY r.room_id, r.name
            ORDER BY usage_count DESC
            LIMIT 5;
        """

    def direct_query(self):
        start_time = time.time()
        cursor = self.pg_conn.cursor()
        cursor.execute(self.stats_query)
        cursor.fetchall()
        cursor.close()
        return time.time() - start_time

    def cached_query(self):
        start_time = time.time()
        cache_key = "room_stats"

        # Try to get from cache
        cached_result = self.redis_client.get(cache_key)
        if cached_result:
            return time.time() - start_time

        # If not in cache, query DB and cache result
        cursor = self.pg_conn.cursor()
        cursor.execute(self.stats_query)
        results = cursor.fetchall()
        cursor.close()

        self.redis_client.setex(cache_key, 5, str(results))
        return time.time() - start_time

    def modify_data(self, operation):
        cursor = self.pg_conn.cursor()

        if operation == "insert":
            cursor.execute("""
                INSERT INTO rehearsal (date, customer_id, customer_rate, room_rate, additional_info)
                VALUES (CURRENT_DATE, 1, 5, 5, 'info') RETURNING rehearsal_id
            """)
            rehearsal_id = cursor.fetchone()[0]

            cursor.execute("""
                INSERT INTO rehearsals_in_room (rehearsal_id, room_id, status)
                VALUES (%s, 1, 1)
            """, (rehearsal_id,))

        elif operation == "update":
            cursor.execute("""
                UPDATE rehearsal
                SET customer_rate = 5
                WHERE rehearsal_id IN (
                    SELECT rehearsal_id FROM rehearsal
                    ORDER BY RANDOM() LIMIT 1
                )
            """)

        elif operation == "delete":
            # Delete from rehearsals_in_room first
            cursor.execute("""
                DELETE FROM rehearsals_in_room
                WHERE rehearsal_id IN (
                    SELECT rehearsal_id FROM rehearsals_in_room
                    ORDER BY RANDOM() LIMIT 1
                )
            """)

        self.pg_conn.commit()
        cursor.close()

    def run_test(self, test_duration=60, modification=None):
        direct_times = []
        cached_times = []

        start_time = time.time()
        last_modify_time = start_time

        while time.time() - start_time < test_duration:
            direct_times.append(self.direct_query())
            cached_times.append(self.cached_query())

            if modification and time.time() - last_modify_time >= 10:
                self.modify_data(modification)
                last_modify_time = time.time()

            time.sleep(5)

        return direct_times, cached_times

    def plot_results(self, scenario_name, direct_times, cached_times):
        plt.figure(figsize=(10, 6))
        plt.plot(direct_times, label='Direct Query')
        plt.plot(cached_times, label='Cached Query')
        plt.title(f'Query Performance - {scenario_name}')
        plt.xlabel('Query Number')
        plt.ylabel('Time (seconds)')
        plt.legend()
        plt.savefig(f'performance_{scenario_name}.png')
        plt.close()


def main():
    analyzer = PerformanceAnalyzer()

    scenarios = [
        ("No Modifications", None),
        ("With Inserts", "insert"),
        ("With Updates", "update"),
        ("With Deletions", "delete")
    ]

    for scenario_name, modification in scenarios:
        print(f"Running test: {scenario_name}")
        direct_times, cached_times = analyzer.run_test(
            test_duration=60,
            modification=modification
        )
        analyzer.plot_results(scenario_name, direct_times, cached_times)


if __name__ == "__main__":
    main()
