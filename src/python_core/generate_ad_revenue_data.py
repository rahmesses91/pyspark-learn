import pandas as pd
from faker import Faker
import random
from datetime import datetime, timedelta
import os
import numpy as np

fake = Faker()
Faker.seed(42)
random.seed(42)
np.random.seed(42)

# CONFIGURATION
NUM_NEIGHBORHOODS = 50
NUM_USERS = 5000
NUM_CAMPAIGNS = 200
NUM_IMPRESSIONS = 50000
NUM_CLICKS = 5000  # ~10% CTR baseline
NUM_REVENUE_DAYS = 90  # Last 90 days of revenue data

# OUTPUT DIRECTORY
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "practice_datasets", "revenues")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Constants for realistic ad data
AD_TYPES = ['Display', 'Native', 'Sponsored Post', 'Local Deal', 'Video']
CAMPAIGN_OBJECTIVES = ['Brand Awareness', 'Traffic', 'Conversions', 'Local Reach', 'App Install']
CAMPAIGN_STATUS = ['Active', 'Paused', 'Completed', 'Draft']
BUSINESS_CATEGORIES = [
    'Restaurant', 'Home Services', 'Retail', 'Healthcare', 'Real Estate',
    'Automotive', 'Financial Services', 'Education', 'Fitness', 'Pet Services',
    'Legal Services', 'Beauty & Spa', 'Insurance', 'Travel', 'Entertainment'
]
DEVICE_TYPES = ['Mobile', 'Desktop', 'Tablet']
AD_PLACEMENTS = ['Feed', 'Right Rail', 'Story', 'Search Results', 'Notification']


def generate_realistic_datetime_2025(start_date, end_date):
    """Generate realistic timestamps reflecting user behavior patterns."""
    base_date = fake.date_between(start_date=start_date, end_date=end_date)
    day_of_week = base_date.weekday()
    is_weekend = day_of_week >= 5
    
    hour_weights = [
        1, 1, 1, 1, 1, 2,        # 12am-5am: very low activity
        3, 5, 8, 8, 6, 5,        # 6am-11am: morning peak
        4, 4, 3, 3, 4, 5,        # 12pm-5pm: afternoon lull
        7, 9, 10, 8, 5, 3        # 6pm-11pm: evening peak
    ]
    
    if is_weekend:
        hour_weights = [w * 1.3 if 9 <= i <= 22 else w for i, w in enumerate(hour_weights)]
    
    hour = random.choices(range(24), weights=hour_weights)[0]
    minute = random.randint(0, 59)
    second = random.randint(0, 59)
    
    return datetime.combine(base_date, datetime.min.time().replace(hour=hour, minute=minute, second=second))


def generate_click_datetime(impression_datetime):
    """Generate click time shortly after impression (usually within seconds to minutes)."""
    delay_seconds = random.choices(
        [random.randint(1, 5), random.randint(5, 30), random.randint(30, 300)],
        weights=[50, 35, 15]
    )[0]
    return impression_datetime + timedelta(seconds=delay_seconds)


# 1. GENERATE NEIGHBORHOODS
print("Generating neighborhoods...")
neighborhoods = []
neighborhood_types = ['Urban', 'Suburban', 'Rural']
for i in range(1, NUM_NEIGHBORHOODS + 1):
    population = random.randint(5000, 80000)
    households = int(population / random.uniform(2.2, 3.0))
    neighborhoods.append({
        "neighborhood_id": i,
        "name": f"{fake.city()} {random.choice(['Heights', 'Park', 'Village', 'Commons', 'Grove'])}",
        "city": fake.city(),
        "state": fake.state_abbr(),
        "zip_code": fake.zipcode(),
        "population": population,
        "households": households,
        "median_income": random.randint(45000, 180000),
        "neighborhood_type": random.choices(neighborhood_types, weights=[30, 50, 20])[0],
        "latitude": round(random.uniform(25.0, 48.0), 6),
        "longitude": round(random.uniform(-125.0, -70.0), 6),
        "created_at": fake.date_between(start_date=datetime(2020, 1, 1), end_date=datetime(2023, 12, 31))
    })
df_neighborhood = pd.DataFrame(neighborhoods)
neighborhood_ids = df_neighborhood['neighborhood_id'].tolist()

# 2. GENERATE USERS
print("Generating users...")
users = []
age_groups = ['18-24', '25-34', '35-44', '45-54', '55-64', '65+']
for i in range(1, NUM_USERS + 1):
    join_date = generate_realistic_datetime_2025(
        start_date=datetime(2022, 1, 1),
        end_date=datetime(2025, 10, 31)
    )
    last_active = generate_realistic_datetime_2025(
        start_date=join_date.date() if isinstance(join_date, datetime) else join_date,
        end_date=datetime(2025, 12, 15)
    )
    users.append({
        "user_id": i,
        "name": fake.name(),
        "email": fake.email(),
        "neighborhood_id": random.choice(neighborhood_ids),
        "age_group": random.choices(age_groups, weights=[15, 25, 20, 18, 12, 10])[0],
        "gender": random.choices(['Male', 'Female', 'Other', 'Prefer not to say'], weights=[48, 48, 2, 2])[0],
        "is_verified": random.choices([True, False], weights=[70, 30])[0],
        "is_active": random.choices([True, False], weights=[85, 15])[0],
        "notification_enabled": random.choices([True, False], weights=[65, 35])[0],
        "device_type": random.choice(DEVICE_TYPES),
        "created_at": join_date,
        "last_active_at": last_active
    })
df_user = pd.DataFrame(users)
user_ids = df_user['user_id'].tolist()
active_user_ids = df_user[df_user['is_active'] == True]['user_id'].tolist()

# 3. GENERATE AD CAMPAIGNS
print("Generating ad campaigns...")
campaigns = []
advertisers = [fake.company() for _ in range(50)]  # 50 unique advertisers

for i in range(1, NUM_CAMPAIGNS + 1):
    start_date = generate_realistic_datetime_2025(
        start_date=datetime(2025, 1, 1),
        end_date=datetime(2025, 9, 30)
    ).date()
    
    duration_days = random.choices([7, 14, 30, 60, 90], weights=[20, 25, 30, 15, 10])[0]
    end_date = start_date + timedelta(days=duration_days)
    
    daily_budget = round(random.uniform(50, 2000), 2)
    total_budget = round(daily_budget * duration_days * random.uniform(0.7, 1.0), 2)
    
    status = 'Completed' if end_date < datetime(2025, 12, 1).date() else random.choices(
        ['Active', 'Paused', 'Draft'],
        weights=[60, 25, 15]
    )[0]
    
    target_neighborhoods = random.sample(neighborhood_ids, k=random.randint(1, min(10, len(neighborhood_ids))))
    
    campaigns.append({
        "campaign_id": i,
        "campaign_name": f"{random.choice(['Winter', 'Spring', 'Summer', 'Fall', 'Holiday', 'Local'])} {random.choice(['Promo', 'Sale', 'Launch', 'Special', 'Event'])} {fake.word().title()}",
        "advertiser_id": random.randint(1, 50),
        "advertiser_name": random.choice(advertisers),
        "business_category": random.choice(BUSINESS_CATEGORIES),
        "campaign_objective": random.choice(CAMPAIGN_OBJECTIVES),
        "ad_type": random.choice(AD_TYPES),
        "target_neighborhood_ids": str(target_neighborhoods),
        "target_age_groups": str(random.sample(age_groups, k=random.randint(2, len(age_groups)))),
        "daily_budget": daily_budget,
        "total_budget": total_budget,
        "bid_strategy": random.choice(['CPC', 'CPM', 'CPA']),
        "bid_amount": round(random.uniform(0.5, 15.0), 2),
        "status": status,
        "start_date": start_date,
        "end_date": end_date,
        "created_at": start_date - timedelta(days=random.randint(1, 7))
    })
df_campaign = pd.DataFrame(campaigns)
active_campaign_ids = df_campaign[df_campaign['status'].isin(['Active', 'Completed'])]['campaign_id'].tolist()

# 4. GENERATE AD IMPRESSIONS
print("Generating ad impressions...")
impressions = []

for i in range(1, NUM_IMPRESSIONS + 1):
    campaign = df_campaign[df_campaign['campaign_id'].isin(active_campaign_ids)].sample(1).iloc[0]
    
    impression_date = generate_realistic_datetime_2025(
        start_date=campaign['start_date'],
        end_date=min(campaign['end_date'], datetime(2025, 12, 15).date())
    )
    
    user_id = random.choice(active_user_ids)
    user_row = df_user[df_user['user_id'] == user_id].iloc[0]
    
    impressions.append({
        "impression_id": i,
        "campaign_id": campaign['campaign_id'],
        "user_id": user_id,
        "neighborhood_id": user_row['neighborhood_id'],
        "ad_type": campaign['ad_type'],
        "ad_placement": random.choice(AD_PLACEMENTS),
        "device_type": user_row['device_type'],
        "is_viewable": random.choices([True, False], weights=[85, 15])[0],
        "view_duration_seconds": random.choices(
            [random.randint(0, 2), random.randint(2, 10), random.randint(10, 60)],
            weights=[30, 50, 20]
        )[0],
        "session_id": fake.uuid4()[:8],
        "created_at": impression_date
    })

df_impression = pd.DataFrame(impressions)
impression_records = df_impression.to_dict('records')

# 5. GENERATE AD CLICKS
print("Generating ad clicks...")
clicks = []
clicked_impressions = random.sample(impression_records, k=min(NUM_CLICKS, len(impression_records)))

for i, imp in enumerate(clicked_impressions, 1):
    click_time = generate_click_datetime(imp['created_at'])
    
    clicks.append({
        "click_id": i,
        "impression_id": imp['impression_id'],
        "campaign_id": imp['campaign_id'],
        "user_id": imp['user_id'],
        "neighborhood_id": imp['neighborhood_id'],
        "device_type": imp['device_type'],
        "click_position": random.choice(['headline', 'image', 'cta_button', 'description']),
        "landing_page_url": fake.url(),
        "is_conversion": random.choices([True, False], weights=[15, 85])[0],
        "created_at": click_time
    })

df_click = pd.DataFrame(clicks)

# 6. GENERATE AD REVENUE (Daily aggregates per campaign)
print("Generating ad revenue...")
revenues = []
revenue_id = 1

end_date = datetime(2025, 12, 15).date()
start_date = end_date - timedelta(days=NUM_REVENUE_DAYS)
date_range = [start_date + timedelta(days=x) for x in range(NUM_REVENUE_DAYS)]

for campaign in df_campaign[df_campaign['status'].isin(['Active', 'Completed'])].to_dict('records'):
    campaign_dates = [d for d in date_range if campaign['start_date'] <= d <= campaign['end_date']]
    
    for rev_date in campaign_dates:
        daily_impressions = random.randint(100, 5000)
        daily_clicks = int(daily_impressions * random.uniform(0.02, 0.15))  # 2-15% CTR
        daily_conversions = int(daily_clicks * random.uniform(0.05, 0.25))  # 5-25% conversion rate
        
        if campaign['bid_strategy'] == 'CPM':
            revenue = round((daily_impressions / 1000) * campaign['bid_amount'] * random.uniform(0.8, 1.2), 2)
        elif campaign['bid_strategy'] == 'CPC':
            revenue = round(daily_clicks * campaign['bid_amount'] * random.uniform(0.8, 1.2), 2)
        else:  # CPA
            revenue = round(daily_conversions * campaign['bid_amount'] * 10 * random.uniform(0.8, 1.2), 2)
        
        spend = round(revenue * random.uniform(0.6, 0.85), 2)  # Platform margin
        
        revenues.append({
            "revenue_id": revenue_id,
            "campaign_id": campaign['campaign_id'],
            "advertiser_id": campaign['advertiser_id'],
            "advertiser_name": campaign['advertiser_name'],
            "business_category": campaign['business_category'],
            "revenue_date": rev_date,
            "impressions": daily_impressions,
            "clicks": daily_clicks,
            "conversions": daily_conversions,
            "revenue_amount": revenue,
            "advertiser_spend": spend,
            "cpm": round((revenue / daily_impressions) * 1000, 2) if daily_impressions > 0 else 0,
            "cpc": round(revenue / daily_clicks, 2) if daily_clicks > 0 else 0,
            "cpa": round(revenue / daily_conversions, 2) if daily_conversions > 0 else 0,
            "ctr": round((daily_clicks / daily_impressions) * 100, 2) if daily_impressions > 0 else 0,
            "conversion_rate": round((daily_conversions / daily_clicks) * 100, 2) if daily_clicks > 0 else 0,
            "created_at": datetime.combine(rev_date, datetime.min.time()) + timedelta(hours=23, minutes=59)
        })
        revenue_id += 1

df_revenue = pd.DataFrame(revenues)

# EXPORT TO CSV
print(f"\nSaving files to: {OUTPUT_DIR}")
df_neighborhood.to_csv(os.path.join(OUTPUT_DIR, "neighborhoods.csv"), index=False)
df_user.to_csv(os.path.join(OUTPUT_DIR, "users.csv"), index=False)
df_campaign.to_csv(os.path.join(OUTPUT_DIR, "ad_campaigns.csv"), index=False)
df_impression.to_csv(os.path.join(OUTPUT_DIR, "ad_impressions.csv"), index=False)
df_click.to_csv(os.path.join(OUTPUT_DIR, "ad_clicks.csv"), index=False)
df_revenue.to_csv(os.path.join(OUTPUT_DIR, "ad_revenue.csv"), index=False)

total_records = len(df_neighborhood) + len(df_user) + len(df_campaign) + len(df_impression) + len(df_click) + len(df_revenue)
print(f"\nSuccessfully generated {total_records:,} total records:")
print(f"  - Neighborhoods: {len(df_neighborhood):,}")
print(f"  - Users: {len(df_user):,}")
print(f"  - Ad Campaigns: {len(df_campaign):,}")
print(f"  - Ad Impressions: {len(df_impression):,}")
print(f"  - Ad Clicks: {len(df_click):,}")
print(f"  - Ad Revenue (daily): {len(df_revenue):,}")

print("\n--- Sample Data Preview ---")
print("\nNeighborhoods (first 3 rows):")
print(df_neighborhood.head(3).to_string())
print("\nUsers (first 3 rows):")
print(df_user[['user_id', 'name', 'neighborhood_id', 'age_group', 'is_active']].head(3).to_string())
print("\nAd Campaigns (first 3 rows):")
print(df_campaign[['campaign_id', 'campaign_name', 'advertiser_name', 'total_budget', 'status']].head(3).to_string())
print("\nAd Impressions (first 3 rows):")
print(df_impression[['impression_id', 'campaign_id', 'user_id', 'ad_placement', 'device_type']].head(3).to_string())
print("\nAd Clicks (first 3 rows):")
print(df_click[['click_id', 'impression_id', 'campaign_id', 'is_conversion']].head(3).to_string())
print("\nAd Revenue (first 3 rows):")
print(df_revenue[['revenue_id', 'campaign_id', 'revenue_date', 'impressions', 'clicks', 'revenue_amount', 'ctr']].head(3).to_string())
