" imports "
import math
import C_Connect4 as c4
import random as rd


#Global constants
TREE_DEPTH = 3
SONDAGE_NB_GAMES = 11


def minimax(player, game, depth, maximizing_player, fct, coeffs):
    """ The standard minimax function
        node <class> __main__.Node
        depth <class> int
        maximizing_player <class> bool """
    #print("depth", depth)
    if depth == 0 or game.end:
        a = fct(player, game, game.end, depth == 0, depth, coeffs)
        #print((TREE_DEPTH - depth) * "      ","value", a)
        return a
    if maximizing_player:
        value = -math.inf
        dict = {}
        for i in game.list_of_free_columns():
            game2 = game.add_a_coin(i)
            #print((TREE_DEPTH - depth) * "      ","son", i)
            val2 = minimax(-player, game2, depth - 1, False, fct, coeffs)
            dict[game2] = val2
        value = dict.get(max(dict, key=dict.get))
        if depth == TREE_DEPTH:
            lg = []
            for x in dict:
                if dict[x] == value:
                    lg.append(x)
            return rd.choice(lg)
        else:
            #print((TREE_DEPTH - depth) * "      ", maximizing_player, "chosen value", value)
            return value
    else:
        value = math.inf
        dict = {}
        for i in game.list_of_free_columns():
            game2 = game.add_a_coin(i)
            #print((TREE_DEPTH - depth) * "      ","son", i)
            val2 = minimax(-player, game2, depth - 1, True, fct, coeffs)
            dict[game2] = val2
        value = dict.get(min(dict, key=dict.get))
        #print((TREE_DEPTH - depth) * "      ",maximizing_player, "chosen value", value)
        return value


def alphabeta(player, game, depth, alpha, beta, maximizing_player, fct, coeffs):
    """ The standard minimax function
        node <class> __main__.Node
        depth <class> int
        maximizing_player <class> bool """
    #print("depth", depth)
    cdef float a = 0
    if depth == 0 or game.end:
        a = fct(player, game, game.end, depth == 0, depth, coeffs)
        #print((TREE_DEPTH - depth) * "      ","value", a)
        return a
    cdef float value = -1000000
    cdef int chosen_game = -1
    cdef list L = game.list_of_free_columns()
    if maximizing_player:
        rd.shuffle(L)
        for i in L:
            game2 = game.add_a_coin(i)
            #print((TREE_DEPTH - depth) * "      ","son", i, alpha, beta)
            eval = alphabeta(-player, game2, depth-1, alpha, beta, False, fct, coeffs)
            if value < eval:
                chosen_game = i
            value = max(value, eval)
            alpha = max(alpha, value)
            if alpha >= beta:
                break
        if depth == TREE_DEPTH:
            return game.add_a_coin(chosen_game)
        else:
            #print((TREE_DEPTH - depth) * "      ", maximizing_player, "chosen value", value)
            return value
    else:
        value = 1000000
        #L = game.list_of_free_columns()
        rd.shuffle(L)
        for i in L:
            game2 = game.add_a_coin(i)
            #print((TREE_DEPTH - depth) * "      ", "son", i, alpha, beta)
            eval = alphabeta(-player, game2, depth-1, alpha, beta, True, fct, coeffs)
            value = min(value, eval)
            beta = min(beta, value)
            if alpha >= beta:
                break
        #print((TREE_DEPTH - depth) * "      ",maximizing_player, "chosen value", value)
        return value



cpdef int partie(ia1, list coeffs1, ia2, list coeffs2): #puts 2 IAs against eachother and returns the winner
    game = c4.Connect4()
    cdef int p = rd.choice([1, 2])
    game.player = p
    #print(p)
    while not game.end:
        if p == 1:
            game = ia1(game, coeffs1)
        else:
            game = ia2(game, coeffs2)
        p = 1 if p == 2 else 2
        #print(game)
    #print(game)
    print("END")
    #print("Winner:", game.winner)
    return game.winner






