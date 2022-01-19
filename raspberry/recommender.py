from pickle import FALSE, TRUE
import psycopg2
import random
import pygame
import google.cloud.texttospeech as tts
import google.cloud.texttospeech as tts
from datetime import datetime
from datetime import timedelta
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
    # print(db_version)

    # Get tables
    location_query = cursor.execute("select * from location")
    location_table = cursor.fetchall()
    for row in location_table:
        print(row)

    activities_query = cursor.execute("select * from activities")
    activities_table = cursor.fetchall()
    for row in activities_table:
        print(row)
    steps_query = cursor.execute("select * from steps where time BETWEEN NOW() - INTERVAL '24 HOURS' AND NOW()")
        #"select * from steps where time BETWEEN NOW() - INTERVAL '24 HOURS' AND NOW()")
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
    forecast_query = cursor.execute("select * from forecast")
    weather_forecast_table = cursor.fetchall()
    for row in weather_forecast_table:
        print(row)
    # Music library
    music_library = {
        "Bruno Mars_The Lazy Song": "./songs/Bruno Mars_The Lazy Song.mp3",
        "CeeLo Green_FUCK YOU": "./songs/CeeLo Green_FUCK YOU.mp3",
        "Clean Bandit_Rockabye": "./songs/Clean Bandit_Rockabye.mp3",
        "Dua Lipa_IDGAF": "./songs/Dua Lipa_IDGAF.mp3",
        "Galantis_No Money": "./songs/Galantis_No Money.mp3",
        "Jason Derulo_Trumpets": "./songs/Jason Derulo_Trumpets.mp3",
        "Jess Glynne_I'll Be There": "./songs/Jess Glynne_I'll Be There.mp3",
        "Panic! At The Disco_High Hopes": "./songs/Panic! At The Disco_High Hopes.mp3",
        "Tina Turner_The Best": "./songs/Tina Turner_The Best.mp3",
    }
    
    # calculate outdoor_activity
    outdoor_activity_duration = checkActivity(activities_table)

    # Obtain recommendations
    light_recommendation, vitamin_recommendation, minutes_lamp = obtainLightRecommendation(
        weather_table=weather_table, outdoor_activity_duration=outdoor_activity_duration)
    activity_recommendation = obtainActivityRecommendation(checkSteps(steps_table),weather_forecast_table)
    music_recommendation, song_path = obtainMusicRecommendation(
        music_library=music_library)
    location_recommendation = obtainLocationRecommendation(location_table)
    
    
   

    # Obtain text to speech
    filename = textToSpeech(music_recommendation=music_recommendation, activity_recommendation=activity_recommendation,
                            vitamin_recommendation=vitamin_recommendation, light_recommendation=light_recommendation, location_recommendation=location_recommendation)

    # Play recommendations
    playAudio('recommendations/' + filename)
    
    # Play the recommended song
    playAudio("." + song_path)
    
    # Turn on lamp
    if minutes_lamp > 0:
        turnOnLamp(minutes_lamp)

    


def textToSpeech(music_recommendation, activity_recommendation, vitamin_recommendation, light_recommendation, location_recommendation):
    # Call text to speach API and pass the strings
    voice_name = "en-GB-Wavenet-C"
    text = "\n \n \n Hi. Welcome home! \n\n,"+  activity_recommendation + "\n," + location_recommendation + "\n,"+ vitamin_recommendation + "\n," + light_recommendation + "\n,"  + music_recommendation
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
    switch.switchon(minutes)


# ALGORITHM
# 1. Obtain the data from todays date
today = datetime.now()

# 2. Check for every data point


def checkLocation(location_table):
    pastLocations = []
    for row in location_table:
        if row[4] not in pastLocations:
            pastLocations.append(row[4])
    if len(pastLocations) > 3:
        return True
    return False


def checkActivity(activities_table):
    ACTIVITY_DURATION = 5
    walking_duration = 0
    running_duration = 0
    still_duration = 0
    biking_duration = 0

    for row in activities_table:
        if 'WALKING' == row[1]:
            walking_duration += ACTIVITY_DURATION
        elif 'RUNNING' == row[1]:
            running_duration += ACTIVITY_DURATION
        elif 'STILL' == row[1]:
            still_duration += ACTIVITY_DURATION
        elif 'ON_BICYCLE' == row[1]:
            biking_duration += ACTIVITY_DURATION

    outdoor_activity_duration = walking_duration + running_duration + biking_duration

    return outdoor_activity_duration


""" different activity types:
IN_VEHICLE
ON_BICYCLE
ON_FOOT
RUNNING
STILL
TILTING
UNKNOWN
WALKING
INVALID (used for parsing errors) """


def checkSteps(steps_table):
    
    current_steps = steps_table[-1][1]-steps_table[1][1]
    print("steps are:",current_steps)
    return current_steps


def obtainLocationRecommendation(location_table):
    location_recommendation = ""
    places_visited = checkLocation(location_table)
    if places_visited > 5:
        pass
    else:
        location_recommendation+="It seems like you have been in the same place today"
        if datetime.now().strftime("%H:%M") > "20:00":# and weather not too Bad:
            location_recommendation+="It could be a good idea to go on a short walk and get some fresh air."
        else:
            location_recommendation+="It could be a good idea to change your environment."
    return location_recommendation

def obtainActivityRecommendation(current_steps,weather_forecast_table):
    # Recommendation for activity
    activity_recommendation = ""
    
    
    if current_steps < 10000: #and (not hasActivityRunning and not hasActivityCycling):
        activity_recommendation+= "You didn't reach the recommended activity goal."
        # check the weather and the time for recommending exercises
        if datetime.now().strftime("%H:%M") > "20:00":
            activity_recommendation+= "It is already a bit late for today, but here are some recommendations for tomorrow:"
            # check tomorrow weather
            current_time = datetime.now()
            tomorrow_time = current_time + timedelta(hours=16)
            tomorrow_timestamp = tomorrow_time.timestamp()
            for row in weather_forecast_table:
                if int(row[3]) > tomorrow_timestamp:
                    if row[4] is not "Clouds" or row[4] is not "Thunderstorm" or row[4] is not "Snow":
                        tomorrow_weather_good = True
                        break
                    else: 
                        tomorrow_weather_good = False

            if tomorrow_weather_good:
                activity_messages = ["It seems like it might rain tomorrow, but you can still do some activities at home. Dancing can be a great way of getting some exercise while having fun!"]
            
            else:
                activity_messagess = ["You could go for a 20 minutes walk!","How about taking your bike and exploring a bit around?", "Do you need to run some errands? Why don't you take a walk around the block and get what you need?"]    

        
            
        else:
            activity_recommendation+= "You still have time to reach the goal. Here are some recommendations based on the weather forecast."
            # check today weather
            current_time = datetime.now()
            current_timestamp = current_time.timestamp()
            current_plus3hours = current_timestamp + 3*3600
            
            for row in weather_forecast_table:
                if int(row[3]) > current_timestamp and int(row[3]) < current_plus3hours:
                    if row[4] is not "Clouds" or row[4] is not "Thunderstorm" or row[4] is not "Snow":
                        today_weather_good = True
                        break
                    else: 
                        today_weather_good = False
                        
            if today_weather_good:
                activity_messages = ["It seems like it might rain later, but you can still do some activities at home. Dancing can be a great way of getting some exercise while having fun!"]

            else:    
                activity_messages = ["You could go for a 20 minutes walk!","How about taking your bike and exploring a bit around?", "Do you need to run some errands? Why don't you take a walk around the block and get what you need?"]    

        activity_recommendation += random.choice(activity_messages)

    elif current_steps < 10000:# and (hasActivityRunning or hasActivityCycling):
        activity_recommendation+="Congratulations! You reached the recommended actvity goal for the day! Keep it like this."

    elif current_steps >= 10000:
        activity_recommendation+="Congratulations! You reached the recommended actvity goal for the day! Keep it like this."

    return activity_recommendation


def obtainMusicRecommendation(music_library):
    # Music recommendation
    music_recommendation = "For today's music recomendation,"

    music_intro_messagess = ["here is a mood booster song!",
                             "have you danced yet to this beat?", "we have the perfect song to lift your mood!"]

    # Get a random intro message from the song
    music_recommendation+=random.choice(music_intro_messagess)

    # Get a random song from the library
    song, path = random.choice(list(music_library.items()))
    song_artist = song.split("_")[0]
    song_name = song.split("_")[1]

    music_recommendation+="This is " + song_name + " by " + song_artist

    return music_recommendation, path


def obtainLightRecommendation(weather_table, outdoor_activity_duration):
    vitamin_intake = ""
    enough_light = False
    light_recommendation = ""
    outdoor_activity_today = False
    SUFFICIENT_LIGHT = 200
    SUFFICIENT_OUTDOOR_ACTIVITY = 30

    # light_exposure is calculated by cloudiness during the last day
    # calculate cloudiness average
    cloud_sum = 0
    cloud_count = 0
    cloud_avg = 0
    for row in weather_table:
        cloud_sum += row[2]
        cloud_count += 1
    cloud_avg = cloud_sum / cloud_count

    # calculate uvi average
    uvi_sum = 0
    uvi_count = 0
    uvi_avg = 0
    for row in weather_table:
        uvi_sum += row[1]
        uvi_count += 1
    uvi_avg = uvi_sum / uvi_count

    

    # combine outdoor_activity with cloudiness average to get light_exposure
    UVI_SCALING = 2
    light_exposure = (100 - cloud_avg) * uvi_avg * UVI_SCALING
    print(light_exposure)
    # sufficient_exp = (100 - 50) * 2 * UVI_SCALING
    print(outdoor_activity_duration)

    if SUFFICIENT_LIGHT < light_exposure and SUFFICIENT_OUTDOOR_ACTIVITY < outdoor_activity_duration:
        enough_light = True
    else:
        enough_light = False

    if not enough_light:
        # If not enough light, recommend vitamin intake
        vitamin_intake+="You didn't get enough light exposure today. To compensate you could take one drop of vitamin D, which equals 1000 I.U."

        # Turn on the lamp. For how long?
        minutes_lamp = 30
        light_recommendation+="The lamp will turn on when the music finished playing. "
        light_recommendation+="Please come closer to the device when it turns on, the lamp will be turned on for "
        light_recommendation+=str(minutes_lamp)
        light_recommendation+=" minutes."

    else:
        vitamin_intake+="You got enough sunlight and don't need to take a supplementary vitamin today."
        minutes_lamp = 0

    return light_recommendation, vitamin_intake, minutes_lamp


if __name__ == "__main__":
    main()


# VARIABLES

