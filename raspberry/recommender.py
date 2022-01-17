import psycopg2
import random
import pygame
import google.cloud.texttospeech as tts
import google.cloud.texttospeech as tts
from datetime import datetime
from pandas import DataFrame
import switch

def main():

    # Instanciate database
    hostname = '127.0.0.1'
    username = 'pi'
    password = 'pi'
    database = 'saddb'

    connection = psycopg2.connect(
        host=hostname, user=username, password=password, database=database)
    cursor = connection.cursor()


    #cursor.execute('SELECT version()')
    #db_version = cursor.fetchone()
    #print(db_version)
    
    # Get tables
    location_query = cursor.execute("select * from location")
    location_table = cursor.fetchall()
    for row in location_table:
        print(row)
        
    activities_query = cursor.execute("select * from activities")
    activities_table = cursor.fetchall()
    for row in activities_table:
        print(row)
    steps_query = cursor.execute("select * from steps")
    steps_table = cursor.fetchall()
    for row in steps_table:
        print(row)
    for row in steps_table:
        print(row[1])
    
    weather_query = cursor.execute("select * from weather")
    weather_table = cursor.fetchall()
    for row in weather_table:
        print(row)    
    #social_table = cursor.execute("select * from social")

    # Music library
    music_library = {
        # Define the songs on the library with similar naming to this:
        "artist_song": "songs/artist_song",
    }

    # Obtain recommendations
    light_recommendation, vitamin_recommendation, minutes_lamp = obtainLightRecommendation()
    activity_recommendation = obtainActivityRecommendation()
    music_recommendation, song_path = obtainMusicRecommendation(
        music_library=music_library)

    # Obtain text to speech
    filename = textToSpeech(music_recommendation=music_recommendation, activity_recommendation=activity_recommendation,
                            vitamin_recommendation=vitamin_recommendation, light_recommendation=light_recommendation)

    # Play recommendations
    playAudio('recommendations/' + filename)

    # Turn on lamp
    if minutes_lamp > 0:
        turnOnLamp(minutes_lamp)

    # Play the recommended song
    playAudio('songs/' + song_path)


def textToSpeech(music_recommendation, activity_recommendation, social_recommendation, vitamin_recommendation, light_recommendation):
    # Call text to speach API and pass the strings
    voice_name = "en-GB-Wavenet-C"
    text = social_recommendation + "\n" + vitamin_recommendation + "\n" + \
        light_recommendation + "\n" + activity_recommendation + "\n" + music_recommendation
    language_code = "-".join(voice_name.split("-")[:2])
    text_input = tts.SynthesisInput(text=text)
    voice_params = tts.VoiceSelectionParams(
        language_code=language_code, name=voice_name
    )
    audio_config = tts.AudioConfig(audio_encoding=tts.AudioEncoding.LINEAR16)

    client = tts.TextToSpeechClient.from_service_account_json("./key.json")
    response = client.synthesize_speech(
        input=text_input, voice=voice_params, audio_config=audio_config
    )

    filename = f"{datetime.now()}.wav"
    with open('recommendations/' + filename, "wb") as out:
        out.write(response.audio_content)
        print(f'Generated speech saved to "{filename}"')

    return filename


def playAudio(song_path):
    pygame.mixer.init()
    pygame.mixer.music.load(song_path)
    pygame.mixer.music.set_volume(1.0)
    pygame.mixer.music.play()
    while pygame.mixer.music.get_busy() == True:
        pass


def turnOnLamp(minutes):
    # Call the lamp swith with a timer of X minutes
    switch.main(minutes)
    # ALGORITHM
    # 1. Obtain the data from todays date
    today = datetime.now()

# 2. Check for every data point


def checkLocation(today, location_table):
    pass


def checkActivity(today, activity_table):
    pass


def checkSteps(today, steps_table):
    current_steps = steps_table(today)
    pass


def obtainActivityRecommendation():
    # Recommendation for activity
    activity_recommendation = ""
    if current_steps < 10000 and (not hasActivityRunning and not hasActivityCycling):
        activity_recommendation.append(
            "You didn't reach the recommended activity goal.")
        # check the weather and the time for recommending exercises
        if current_time > "20:00:00":
            activity_recommendation.append(
                "It is already a bit late for today, but here are some recommendations for tomorrow:")
            # check tomorrow weather
        else:
            activity_recommendation.append(
                "You still have time to reach the goal. Here are some recommendation based on the weather forecast")
            # check todays weather

    elif current_steps < 10000 and (hasActivityRunning or hasActivityCycling):
        activity_recommendation.append(
            "Congratulations you reached the recommended actvity goal for the day! Keep it like this")

    elif current_steps >= 10000:
        activity_recommendation.append(
            "Congratulations you reached the recommended actvity goal for the day! Keep it like this")

    return activity_recommendation


def obtainMusicRecommendation(music_library):
    # Music recommendation
    music_recommendation = "For today's music recomendation,"

    music_intro_messagess = ["here is a mood booster song!",
                             "have you danced yet to this beat?", "we have the perfect song to lift your mood"]

    # Get a random intro message from the song
    music_recommendation.append(random.choice(music_intro_messagess))

    # Get a random song from the library
    song, path = random.choice(list(music_library.items()))
    song_artist = song.split("_")[1]
    song_name = song.split("_")[1]

    music_recommendation.append("This is " + song_name + " by " + song_artist)

    return music_recommendation, path


def obtainLightRecommendation():
    vitamin_intake = ""
    enough_light = False
    light_recommendation = ""

    if not enough_light:
        # If not enough light, recommend vitamin intake
        vitamin_intake.append(
            "You didn't get enough light exposure today. To compensate you could take ?? of vitamin")

        # Turn on the lamp. For how long?
        minutes_lamp = 10

        light_recommendation.append(
            "Please come closer to the device, the lamp will be turned on for the next ")
        light_recommendation.append(str(minutes_lamp))
        light_recommendation.append(" minutes ")

    else:
        vitamin_intake.append(
            "You don't need to take a supplementary vitamin today")
        minutes_lamp = 0

    return light_recommendation, vitamin_intake, minutes_lamp


if __name__ == "__main__":
    main()


# VARIABLES
current_steps
today_weather
tomorrow_weather
