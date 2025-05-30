dictionary = {
    "zero": 0,
    "jeden": 1,
    "dwa": 2,
    "trzy": 3,
    "cztery": 4,
    "pięć": 5,
    "sześć": 6,
    "siedem": 7,
    "osiem": 8,
    "dziewięć": 9,
    "dziesięć": 10,
    "jedenaście": 11,
    "dwanaście": 12,
    "trzynaście": 13,
    "czternaście": 14,
    "piętnaście": 15,
    "szesnaście": 16,
    "siedemnaście": 17,
    "osiemnaście": 18,
    "dziewiętnaście": 19,
    "dwadzieścia": 20,
    "trzydzieści": 30,
    "czterdzieści": 40,
    "pięćdziesiąt": 50,
    "sześćdziesiąt": 60,
    "siedemdziesiąt": 70,
    "osiemdziesiąt": 80,
    "dziewięćdziesiąt": 90,
    "sto": 100,
    "dwieście": 200,
    "trzysta": 300,
    "czterysta": 400,
    "pięćset": 500,
    "sześćset": 600,
    "siedemset": 700,
    "osiemset": 800,
    "dziewięćset": 900,
    "tysiąc": 1000,
    "tysiące": 999,
    "tysięcy": 999}

def translate(number):
    sum = 0
    tmp = 0
    for value in number:
        if dictionary[value] == 999:
            sum += tmp * 999
        else:
            sum += dictionary[value]
        tmp += dictionary[value]
    return sum

def sorting(my_list):
    numbers = [translate(value.split()) for value in my_list]
    numbers.sort()
    return numbers

print(sorting(['sto dwadzieścia trzy', 'dwieście dwadzieścia dwa tysiące dwieście dwadzieścia dwa', 'osiemset piętnaście']))
    