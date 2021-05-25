" imports "
import math
import random as rd
import numpy as np
import C_Connect4 as c4
from C_Connect4 cimport Connect4
import C_GenericAlgorithm as ga



cdef int COEFF_1 = 1
cdef int COEFF_2 = 2
cdef int COEFF_3 = -2
cdef int[3] MATRIX_COEFFS = [COEFF_1,COEFF_2,COEFF_3]

cdef int random_game(Connect4 game):
    """  RENDRE GENERIQUE SI POSSIBLE """
    cdef Connect4 game2 = c4.Connect4()
    game2.game_copy(game)
    while not game2.end:
        game2 = game2.add_a_coin(rd.choice(game2.list_of_free_columns()))
    return game2.winner


def sondage_terminal_nodes(int player, Connect4 game, bint end, bint maxdepth, int depth, coeffs):
    """ Sets the value to all terminal nodes, to esp, calculated after playing several random games """
    if maxdepth:                                  #maxdepth = True si on est depth = 0 (si on est en bas de l'arbre)
        if end:
            return player
        else:
            l = [0, 0, 0]
            for i in range(ga.SONDAGE_NB_GAMES):
                winner = random_game(game)
                l[winner] += 1
            esp = (coeffs[0] * l[0] + coeffs[1] * l[1] + coeffs[2] * l[2]) / ( ga.SONDAGE_NB_GAMES * (
                    abs(coeffs[0]) + abs(coeffs[1]) + abs(coeffs[2]))  )  # esp is an float between [-1,1]
            return esp
    else:
        return player * (depth + 1)


def sondage(game, coeffs):
    cdef Connect4 c = ga.alphabeta(-1, game, ga.TREE_DEPTH, -1000000, 1000000, True, sondage_terminal_nodes, coeffs)
    return c
    #return minimax(-1, game, TREE_DEPTH, True, sondage_terminal_nodes, coeffs)

#ga.partie(sondage, [0.5, 1, -1], sondage, [-0.5, 1, -1])


