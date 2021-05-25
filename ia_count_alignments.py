

" imports "
import C_Connect4 as c4
import numpy as np
import math
import random as rd
import C_GenericAlgorithm as ga


" constants "
I = 6
J = 7
EMPTY = 0
# PLAYER_1 = 1
# PLAYER_2 = 2
WEIGHT_2 = 100
WEIGHT_3 = 1000
WEIGHT_4 = 100000
DIRECTIONS = {"TL":[-1,-1], "L":[0,-1], "BL":[1,-1], "B":[1,0], "BR":[1,1], "R":[0,1], "TR":[-1,1], "T":[-1,0]}
OPPOSED = {"TL":"BR", "L":"R", "BL":"TR", "B":"T", "BR":"TL", "R":"L", "TR":"BL"}
MATRIX_COEFFS = np.array([WEIGHT_2,WEIGHT_3,WEIGHT_4])

" additional info "
# Lacking the part removing the one-coin alignments
## doesn't work correctly, so we won't consider the amount of one-coin alignments


class Grid:
    """ A use similar to the Alignements_par_potentiels.py's class Grid, except this time no Cell or Alignment objects are
        considered and the self.matrix works differently """

    def __init__(self, c4, player):
        """ c4 <class> Connect4
            player <class> int <in> [PLAYER_1, PLAYER_2] """

        # this matrix is different from the Alignements_par_potentiels.py : True if the cell was checked before (see below method)
        self.matrix = np.full((I,J), False)
        self.c4 = c4
        self.player = player    # which player has to make a choice (see the player names convention)
        self.alignments_1 = 0   # will contain the number of isolated friendly coins
        self.alignments_2 = 0   # will contain the number of alignments of 2 friendly coins
        self.alignments_3 = 0   # will contain the number of alignments of 3 friendly coins
        self.game_won = False   # used in the GenericAlgorithm.pyx's class Tree in order to stop the generations below the node


    def count_alignments(self):
        """ Will check every friendly coins from left to right, top to down in order to spot the diverse alignments using the
            self.matrix coefficients to avoid counting the same alignment multiple times (before checking -if possible- in a
            direction in top-right/right/bottom-right/bottom, we first check -if possible- whether the location in respectively
            the bottom-left/left/top-left (no need for the top direction) has been checked before
            (ie. if the self.matrix[previous_i][previous_j] is True, with :
            previous_i = <the i associated to the considered location> - DIRECTIONS[<the considered direction>][0]
            previous_j = <the j associated to the considered location> - DIRECTIONS[<the considered direction>][1])
            Also detects a victory. """

        for j in range(J):
            i = self.c4.free_slots[j]
            while i < I:
                if self.c4.grid[i][j] == self.player:
                    coin_has_friendly_neighbors = False
                    for dir in ["TR", "R", "BR", "B"]:
                        aligned_coins = 1
                        past_i = i - DIRECTIONS[dir][0]
                        past_j = j - DIRECTIONS[dir][1]
                        if not self.is_in_grid([past_i, past_j]) or not self.location_already_explored([past_i, past_j]):
                            if not self.is_in_grid([past_i, past_j]):
                                start = None    # a limit
                            elif not self.location_already_explored([past_i, past_j]):
                                start = [past_i, past_j]
                            ii = i + DIRECTIONS[dir][0]
                            jj = j + DIRECTIONS[dir][1]
                            if self.is_in_grid([ii, jj]) and self.c4.grid[ii][jj] != self.player or not self.is_in_grid([ii, jj]):
                                stop = [ii, jj]

                            while self.is_in_grid([ii, jj]) and self.c4.grid[ii][jj] == self.player:
                                aligned_coins += 1
                                if aligned_coins == 4:
                                    self.game_won = True
                                    break
                                ii = ii + DIRECTIONS[dir][0]
                                jj = jj + DIRECTIONS[dir][1]
                                if not self.is_in_grid([ii, jj]):
                                    stop = None    # a limit
                                else:
                                    stop = [ii, jj]
                        if self.game_won:
                            break
                        if self.is_in_grid([past_i, past_j]) and self.location_already_explored([past_i, past_j]):
                            coin_has_friendly_neighbors = True
                        if aligned_coins > 1:
                            coin_has_friendly_neighbors = True
                        if self.keep_alignment(start, stop, aligned_coins, dir):
                            if aligned_coins == 2:
                                self.alignments_2 = self.alignments_2 + 1
                            elif aligned_coins == 3:
                                self.alignments_3 = self.alignments_3 + 1
                    self.matrix[i][j] = True # de la sorte, pas de doublons (alignements plusieurs fois évalués)
                i += 1
                if self.game_won:
                    break
            if self.game_won:
                break


    def keep_alignment(self, start, stop, count, dir):
        """ Detects blocked alignments """

        if count == 3:
            if stop:    # other than None
                if self.is_empty(stop):
                    return True
            return self.is_in_grid(start) and self.is_empty(start)
        vide = 0
        if count == 2:
            if stop:
                if self.is_empty(stop):
                    vide += 1
                    new_coords = self.get_coordinates(stop, dir)
                    if self.is_in_grid(new_coords) and (self.is_empty(new_coords) or self.get_player(new_coords) == self.player):
                        return True
            if self.is_in_grid(start) and self.is_empty(start):
                if vide == 1:
                    return True
                vide += 1
                opposed_dir = self.get_opposed_direction(dir)
                new_coords = self.get_coordinates(start, opposed_dir)
                if self.is_in_grid(new_coords):
                    if self.is_empty(new_coords):
                        if vide == 1:
                            return True
                        new_coords = self.get_coordinates(new_coords, opposed_dir)
                        return self.is_in_grid(new_coords) and (self.is_empty(new_coords) or self.get_player(new_coords) == self.player)
            return False


    def grid_weight(self, grid2, coeffs):
        """ Defines the weight of the grid, based on the number of alignments and their respective weights, and takes the
            opponent's situation into account by subtracting his score from the player's one
            grid2 <class> __main__.Grid """

        if self.game_won:
            return coeffs[2]
        player_score = self.alignments_2 * coeffs[0] + self.alignments_3 * coeffs[1]
        opponent_score = grid2.alignments_2 * coeffs[0] + grid2.alignments_3 * coeffs[1]
        return player_score - opponent_score


    def location_already_explored(self, loc):
        i = loc[0]
        j = loc[1]
        return self.matrix[i][j]


    def get_coordinates(self, start, dir):
        new_i = start[0] + DIRECTIONS[dir][0]
        new_j = start[1] + DIRECTIONS[dir][1]
        return [new_i, new_j]


    def is_empty(self, loc):
        i = loc[0]
        j = loc[1]
        return self.c4.grid[i][j] == EMPTY


    def is_in_grid(self, loc):
        if loc == None:
            return False
        i = loc[0]
        j = loc[1]
        return 0 <= i < I and 0 <= j < J


    def get_opposed_direction(self, dir):
        return OPPOSED[dir]


    def get_player(self, loc):
        i = loc[0]
        j = loc[1]
        return self.c4.grid[i][j]


def ia_weight_count_alignment(game, coeffs):
    g = Grid(game, game.player)
    g.count_alignments()
    player2 = 1 if game.player == 2 else 1
    g2 = Grid(game, player2)
    g2.count_alignments()
    w = g.grid_weight(g2, coeffs)
    #print(w)
    return w/40000



def ia_ca_terminal_nodes(player, game, end, maxdepth, depth, coeffs):
    if maxdepth:                                  #maxdepth = True si on est depth = 0 (si on est en bas de l'arbre)
        if end:
            return player
        else:
            return ia_weight_count_alignment(game, coeffs)
    else:
        return player * (depth + 1)

def ia_ca(game, coeffs):
    return ga.alphabeta(-1, game, ga.TREE_DEPTH, -math.inf, math.inf, True, ia_ca_terminal_nodes, coeffs)


" tests "
"""
c4 = c4.Connect4()
g = Grid(c4, 2) # 1 : ** ; 2 : 00
c4.player = rd.choice([1,2])
for i in range(12):
   a = rd.choice(c4.list_of_free_columns())
   c4 = c4.add_a_coin(a)
   print(c4)
g.count_alignments()
print(g.alignments_1, g.alignments_2, g.alignments_3)
print(c4)
"""

