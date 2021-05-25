cython: wraparound=False
cython: boundscheck=False
cython: cdivision=True
import numpy
cimport numpy
import random as rd
import copy as cp


cdef class Connect4:
    def __init__(self):
        # we initialize the empty cells to 0 ; a cell occupied by a coin from player 1 will be set to 1 (2 for coin from a player 2)
        self.grid = [[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0],[0,0,0,0,0,0,0]]
        self.free_slots = [6, 6, 6, 6, 6, 6, 6]
        self.player = 1
        self.last_played_column = -1  # the last column played <int>
        self.winner = 0  #0 if draw, else 1 or 2 according to player
        self.end = False


    cpdef int game_copy(self, Connect4 game):  #does a copy of a game into the current object
        self.grid = cp.copy(game.grid)
        self.free_slots = cp.copy(game.free_slots)
        self.player = game.player
        self.last_played_column = game.last_played_column
        self.winner = game.winner
        self.end = False
        return 0


    cpdef bint column_is_full(self, int column) :
        return self.free_slots[column] == 0


    cpdef list list_of_free_columns(self):
        cdef list res = []
        for column in range(0, 7):
            if not self.column_is_full(column):
                res.append(column)
        return res


    cpdef list possible_content(self):
        cdef list lst = self.list_of_free_columns()
        cdef list l_possible_games = []
        for i in lst:
            l_possible_games.append(self.add_a_coin(i))
        return l_possible_games


    cpdef Connect4 add_a_coin(self, int column):
        """ Adds a coin to the specified column """
        cdef Connect4 game = Connect4()
        game.game_copy(self)
        if self.player == 1:
            game.grid[self.free_slots[column] - 1][column] = 1
            game.free_slots[column] -= 1
            game.win_check(column)
            game.player = 2
        else:
            game.grid[self.free_slots[column] - 1][column] = 2
            game.free_slots[column] -= 1
            game.win_check(column)
            game.player = 1
        game.last_played_column = column
        return game                                                             ## ?


    cdef bint win_check(self, int column):
        """ Determines whether the game is finished or not """

        cdef int row = self.free_slots[column]

        # the maximum row and column indexes used to search for aligned coins of the same type as the one considered here
        cdef int jmin = column - 3 if column > 2 else 0
        cdef int jmax = column + 3 if column < 4 else 6
        cdef int imin = row - 3 if row > 2 else 0
        cdef int imax = row + 3 if row < 3 else 5

        def count_coins(player, delta, col, dx, dy):
            cdef int res = 0
            cdef int i = self.free_slots[col] + dy
            cdef int j = col + dx
            for k in range(delta):
                if self.grid[i][j] == player:
                    res += 1
                else:
                    break
                i += dy
                j += dx
            return res

        def win_check_aux(player, delta_1, column_1, dx_1, dy_1, delta_2, column_2, dx_2, dy_2):
            cdef int e = count_coins(player, delta_1, column_1, dx_1, dy_1)
            cdef int b = count_coins(player, delta_2, column_2, dx_2, dy_2)
            return e + b

        # aligned coins around the considered coin, in its row
        cdef int h = win_check_aux(self.player, column - jmin, column, -1, 0, jmax - column, column, 1, 0) + 1
        # aligned coins around the considered coin, in its column
        cdef int v = win_check_aux(self.player, imax - row, column, 0, 1, row - imin, column, 0, -1) + 1
        # aligned coins around the considered coin, in its bottom left/top right diagonal
        cdef int d1 = win_check_aux(self.player, min(column - jmin, row - imin), column, -1, -1, min(jmax - column, imax - row), column, 1, 1) + 1
        # aligned coins around the considered coin, in its top left/bottom right diagonal
        cdef int d2 = win_check_aux(self.player, min(column - jmin, imax - row), column, -1, 1, min(jmax - column, row - imin), column, 1, -1) + 1

        if h >= 4 or v >= 4 or d1 >= 4 or d2 >= 4:
            self.winner = self.player
            self.end = True

        # if self.list_of_free_columns() return False, hence if the grid is full
        if self.list_of_free_columns() == []:
            # nobody wins : self.winner remains at 0
            self.end = True

        return self.end


    def __repr__(self):
        """ A simple visualization of the grid using a string
            ** : coin for player 1
            00 : coin for player 2
            .. : empty cell """

        cdef str strg = ""
        for i in range(0, 6):
            for j in range(0, 7):
                if self.grid[i][j] == 0:
                    strg = strg + ".. "
                elif self.grid[i][j] == 1:
                    strg = strg + "** "
                else:
                    strg = strg + "00 "
            strg = strg + "\n"
        return strg
