import C_GenericAlgorithm as ga
import C_ia_count_alignments as ia_ca
import C_ia_potential_alignments as ia_pa
import C_ia_sondage as ia_so
import random as rd

class IA:
    def __init__(self, fct, coeffs):
        self.fct = fct
        self.coeffs = coeffs

    def __repr__(self):
        stg = str(self.fct)[10:-23] + " " + str(self.coeffs)
        return stg

    def child(self):
        child_coeffs = self.coeffs[:]
        for i in range(len(self.coeffs)):
            child_coeffs[i] += rd.randrange(-200, 201)
        if str(self.fct)[10:-23] == "ia_pa":
            child_coeffs[0] = 100000
        return IA(self.fct, child_coeffs)



def random_ia(ia=0): #1 = sondage, 2 = alig_pot, 3 = count_alig
    if ia == 0:
        a = rd.choice([1, 2, 3])
    else:
        a = ia
    if a == 1:
        fct = ia_so.sondage
        coeffs = [rd.randrange(-10000, 10001) for _ in range(3)]
    elif a ==2:
        fct = ia_pa.ia_pa
        coeffs = [rd.randrange(0, 10001) for _ in range(6)]
        coeffs.insert(0, 100000)
    else:
        fct = ia_ca.ia_ca
        coeffs = [rd.randrange(0, 10001) for _ in range(2)]
    return IA(fct, coeffs)


def battle(ia1, ia2): #does 5 games between 2 ias and returns the better one (or a random one between both if no winner)
    L = [0, 0, 0]
    for i in range(0, 5):
        a = ga.partie(ia1.fct, ia1.coeffs, ia2.fct, ia2.coeffs)
        L[a] += 1
        print("Score Round", str(i+1), ":", L)
    if L[1] == L[2]:
        return rd.choice([ia1, ia2])
    elif L[1] > L[2]:
        return ia1
    else:
        return ia2

def championship(ias): #each ai is put against another, the winner wins and creates a child, the loser dies
    L_winners = []
    rd.shuffle(ias)  # randomly shuffles the ia's list
    for a in range(int(len(ias)/2)):
        print("BATTLE", str(a + 1), "OF", str(int(len(ias)/2)), "   ", ias[2*a], "   VS   ", ias[(2*a)+1])
        winner = battle(ias[2*a], ias[(2*a)+1])
        print("WINNER", winner)
        L_winners.append(winner)
    L = L_winners[:]
    for ia in L_winners:
        child = ia.child()
        L.append(child)
    return L


def best_ias_search(nb_iterations, ias=[random_ia(ia=3) for _ in range(20)]): #does nb_iterations of championship
    L_winners = ias[:]
    with open("results_championship3.txt", "a+") as text_file:
        text_file.write(str(ias) + "\n")
    for k in range(nb_iterations):
        print("\nITERATION NUMBER", str(k+1), "OF", nb_iterations)
        L_winners = championship(L_winners)
        with open("results_championship3.txt", "a+") as text_file:
            text_file.write("\nITERATION NUMBER" + str(k+1) + "OF" + str(nb_iterations) + str(L_winners) + "\n")
        print(L_winners)
    return L_winners

#iasl = [random_ia() for _ in range(10)]
#iasl = [IA(ia_ca.ia_ca, [7558, 1345, 6996]), IA(ia_ca.ia_ca, [7532, 1759, 7281]), IA(ia_ca.ia_ca, [7919, 1349, 6762]), IA(ia_ca.ia_ca, [7522, 1894, 7470]), IA(ia_ca.ia_ca, [7651, 1871, 7468]), IA(ia_ca.ia_ca, [7700, 1244, 7140]), IA(ia_ca.ia_ca, [7714, 1750, 7202]), IA(ia_ca.ia_ca, [7924, 1426, 6857]), IA(ia_ca.ia_ca, [7596, 1924, 7501]), IA(ia_ca.ia_ca, [7512, 1695, 7526])]
#print(iasl)
best_ias_search(5) # if you want to use your own ias, define the ias var,  ex: best_ias_search(1, ias=[ia1, ia2])
#[ia_pa [100000, 6306, 8980, 8973, 1476, 458, 3289], ia_pa [100000, 6489, 8834, 9017, 1391, 388, 3432], ia_pa [100000, 6414, 9000, 8842, 1479, 519, 3435], ia_pa [100000, 6107, 8970, 9173, 1647, 342, 3269], ia_pa [100000, 6587, 8823, 9004, 1529, 609, 3432], ia_pa [100000, 6211, 8825, 8911, 1592, 393, 3334], ia_pa [100000, 6619, 8689, 8903, 1391, 556, 3432], ia_pa [100000, 6431, 8918, 8938, 1436, 686, 3556], ia_pa [100000, 5944, 9053, 9186, 1723, 222, 3404], ia_pa [100000, 6531, 8802, 8987, 1687, 749, 3417]]
#[ia_ca [7736, 1054], ia_ca [7861, 1019], ia_ca [7802, 953], ia_ca [7585, 1028], ia_ca [7735, 643], ia_ca [7747, 894], ia_ca [7895, 1086], ia_ca [7781, 790], ia_ca [7734, 1012], ia_ca [7871, 507]]
#[ia_ca [2174, -395], ia_ca [1698, 599], ia_ca [2229, -150], ia_ca [2148, -188], ia_ca [1443, 652], ia_ca [2343, -488], ia_ca [1680, 713], ia_ca [2138, 46], ia_ca [2007, -161], ia_ca [1640, 788]]
#[ia_ca [4976, 4949], ia_ca [4735, 5025], ia_ca [4402, 4852], ia_ca [4630, 5036], ia_ca [4776, 4897], ia_ca [5068, 5147], ia_ca [4871, 5224], ia_ca [4398, 4698], ia_ca [4431, 4958], ia_ca [4897, 4898]]
#[ia_ca [1765, 4393], ia_ca [1938, 4782], ia_ca [1718, 4547], ia_ca [1862, 4590], ia_ca [2052, 4633], ia_ca [1612, 4544], ia_ca [2102, 4598], ia_ca [1617, 4693], ia_ca [1852, 4574], ia_ca [2190, 4762]]
#[ia_ca [5329, 4476], ia_ca [5465, 4687], ia_ca [5004, 4508], ia_ca [5280, 4406], ia_ca [5093, 4254], ia_ca [5384, 4276], ia_ca [5467, 4537], ia_ca [4887, 4683], ia_ca [5211, 4505], ia_ca [5238, 4225]]
