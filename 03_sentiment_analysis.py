import pandas as pd
import pyodbc
import nltk
from nltk.sentiment import SentimentIntensityAnalyzer
# Download the VADER lexicon if not already downloaded
# nltk.download('vader_lexicon')
# from nltk.corpus import stopwords
# from nltk.tokenize import word_tokenize
# from nltk.stem import WordNetLemmatizer

# nltk.download('all', download_dir='D:/App files (self)/nltk_data')
# nltk.data.path.append(r'D:\App files (self)\nltk_data')

# Function to preprocess text data
def preprocess_text(text):
    # Convert text to lowercase
    text = text.lower()
    # Tokenize the text
    tokens = word_tokenize(text)
    # Remove stopwords and non-alphabetic tokens
    filtered_tokens = [word for word in tokens if word.isalpha() and word not in stopwords.words('english')]
    # Lemmatize the tokens
    lemmatizer = WordNetLemmatizer()
    lemmatized_tokens = [lemmatizer.lemmatize(word) for word in filtered_tokens]
    # Join the tokens back into a single string
    return ' '.join(lemmatized_tokens)

# Function to fetch data from SQL Server
def fetch_data_from_sql(driver, server, database, query):
    # Connect to the SQL Server database
    conn = pyodbc.connect(
        f'Driver={driver};'
        f'Server={server};'
        f'Database={database};'
        "Trusted_Connection=yes;"
    )
    # Fetch data from the table using the provided query
    df = pd.read_sql(query, conn)
    
    # Close the connection to free up resources
    conn.close()
    
    return df

# Initialize the Sentiment Intensity Analyzer
sia = SentimentIntensityAnalyzer()

# Function to calculate sentiment scores using VADER
def calculate_sentiment_scores(review):
    # Calculate sentiment scores using VADER
    scores = sia.polarity_scores(review)
    # Return the compound score
    return scores['compound']

# Function to categorize sentiment based on the compound score and the rating
def categorize_sentiment(score, rating):
    if score >= 0.05: # Positive sentiment threshold
        if rating >= 4:
            return 'Positive'
        elif rating == 3:
            return 'Mixed Positive'
        else:
            return 'Mixed Negative'
    elif score <= -0.05: # Negative sentiment threshold
        if rating <= 2:
            return 'Negative'
        elif rating == 3:
            return 'Mixed Negative'
        else:
            return 'Mixed Positive'
    else: # Neutral sentiment
        if rating >= 4:
            return 'Positive'
        elif rating <= 2:
            return 'Negative'
        else:
            return 'Neutral'

# Function to bucket sentiment scores into categories
def sentiment_bucket(score):
    if score >= 0.5:
        return '0.5 to 1.0' # stronly positive
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.5' # mildly positive
    elif -0.5 < score < 0.0:
        return '-0.5 to 0.0' # mildly negative
    else:
        return '-1.0 to -0.5' #strongly negative
    

driver = 'ODBC Driver 17 for SQL Server'
server = 'CECIPC\SQLEXPRESS'
database = 'PortfolioProject_MarketingAnalytics'
query = "SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, ReviewText FROM dbo.customer_reviews"
review_df = fetch_data_from_sql(driver, server, database, query)

# Sentiment analysis on origianl review text
review_df['SentimentScore'] = review_df['ReviewText'].apply(calculate_sentiment_scores)
review_df['SentimentCategory'] = review_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1)
review_df['SentimentBucket'] = review_df['SentimentScore'].apply(sentiment_bucket)

'''
# Sentiment analysis on preprocessed review text
review_df['preprocessed_review'] = review_df['ReviewText'].apply(preprocess_text)
review_df['SentimentScore'] = review_df['preprocessed_review'].apply(calculate_sentiment_scores)
review_df['SentimentCategory'] = review_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1)
review_df['SentimentBucket'] = review_df['SentimentScore'].apply(sentiment_bucket)
'''


print(review_df.head())


review_df.to_csv('D:/DataAnalyst/data-analyst-portfolio-project 0527/customer_reviews_with_sentiment.csv', index=False)