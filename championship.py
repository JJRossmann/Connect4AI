

""" imports """
import C_GenericAlgorithm as ga
import C_ia_count_alignments as ia_ca
import C_ia_potential_alignments as ia_pa
import C_ia_sondage as ia_so
import random as rd
import time as ti


""" constants """

NB_ITERATIONS = 30
POP = 30
NUMBER_GAMES = 5

FILE_PATH_IAS = "./SONxSON_prof3_it30_pop30_bat5_5.txt"
FILE_PATH_TIME_BATTLES = "./SONxSON_prof3_it30_pop30_bat5_timeBat_5.txt"
FILE_PATH_TIME_ITERATIONS = "./SONxSON_prof3_it30_pop30_bat5_timeIt_5.txt"

time_dico_battles = {}
time_dico_iterations = {}


class IA:

    def __init__(self, fct, coeffs):
        self.fct = fct
        self.coeffs = coeffs

    def __repr__(self):
        stg = str(self.coeffs)
        return stg

    def child(self):
        child_coeffs = self.coeffs[:]
        for i in range(len(self.coeffs)):
            child_coeffs[i] += rd.randrange(-200, 201)
        if str(self.fct)[12:17] == "ia_pa":
            child_coeffs[0] = self.coeffs[0]
        return IA(self.fct, child_coeffs)


def random_ia(ia=1): #1 = sondage, 2 = alig_pot, 3 = count_alig
    if ia == 0:
        a = rd.choice([1, 2, 3])
    else:
        a = ia
    if a == 1:
        fct = ia_so.sondage
        coeffs = [rd.randrange(-10000, 10001) for _ in range(3)]
    elif a == 2:
        fct = ia_pa.ia_pa
        coeffs = [rd.randrange(-10000, 10001) for _ in range(6)]
        coeffs.insert(0, 100000)
    else:
        fct = ia_ca.ia_ca
        coeffs = [rd.randrange(0, 10001) for _ in range(3)]
    return IA(fct, coeffs)


class Time():

    def __init__(self, ia1, ia2):
        self.ia1 = ia1
        self.ia2 = ia2
        self.time_list_battle = []

    def update_time_list_battle(self, time_entry):
        self.time_list_battle.append(time_entry)

    def mean_time_battle(self):
        return sum(self.time_list_battle)/len(self.time_list_battle)


def battle(ia1, ia2, it_nb): # does NUMBER_GAMES games between 2 ias and returns the better one (or a random one between both if no winner)
    L = [0, 0, 0]
    global time_dico_battles
    time = Time(ia1, ia2)
    for i in range(0, NUMBER_GAMES):
        start = ti.time()
        a = ga.partie(ia1.fct, ia1.coeffs, ia2.fct, ia2.coeffs)
        stop = ti.time()
        time.update_time_list_battle(stop - start)
        L[a] += 1

    time.mean_time_battle()
    try:
        time_dico_battles[it_nb].append(time)
    except KeyError:
        time_dico_battles[it_nb] = [time]

    print("BATTLE END")
    if L[1] == L[2]:
        print("random_choice")
        return rd.choice([ia1, ia2])
    elif L[1] > L[2]:
        return ia1
    else:
        return ia2


def championship(ias, it_nb): #each ai is put against another, the winner wins and creates a child, the loser dies
    global time_dico_iterations
    L_winners = []
    rd.shuffle(ias)  # randomly shuffles the ia's list
    start = ti.time()
    for a in range(int(len(ias)/2)):
        winner = battle(ias[2*a], ias[(2*a)+1], it_nb)
        L_winners.append(winner)
    stop = ti.time()
    time_dico_iterations[it_nb] = stop - start
    L = L_winners[:]
    for ia in L_winners:
        child = ia.child()
        L.append(child)
    return L


def best_ias_search(NB_ITERATIONS, ias=[random_ia(ia=1) for _ in range(POP)]): #does nb_iterations of championship
# if you want to use your own ias, define the ias var,  ex: best_ias_search(1, ias=[ia1, ia2])
    # ias.append(IA(ia_pa.ia_pa, ia_pa.MATRIX_COEFFS))
    L_winners = ias[:]
    with open(FILE_PATH_IAS , 'a') as f:
        f.write('\n'+ "it. " + "0 : " + str(L_winners))
    for k in range(0, NB_ITERATIONS):
        L_winners = championship(L_winners, k + 1)
        print(L_winners)
        with open(FILE_PATH_IAS , 'a') as f:
            f.write('\n' + "it. " + str(k + 1) + " : " + str(L_winners))
        with open(FILE_PATH_TIME_BATTLES, 'a') as f:
            global time_dico_battles
            f.write('\n' + "it. " + str(k + 1) + " : " + str(time_dico_battles[k + 1]))
        with open(FILE_PATH_TIME_ITERATIONS, 'a') as f:
            global time_dico_iterations
            f.write('\n' + "it. " + str(k + 1) + " : " + str(time_dico_iterations[k + 1]))
    return L_winners


best_ias_search(NB_ITERATIONS)

# a = 0
# length = len(time_dico_battles)
# for i in range(length):
#     length2 = len(time_dico_battles[i+1])
#     for j in range(length2):
#         a += time_dico_battles[i+1][j].mean_time_battle()
# a = a/length2