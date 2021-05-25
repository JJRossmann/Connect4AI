

" imports "
import C_Connect4 as C_c4
from C_Connect4 cimport Connect4
import numpy as np
#cimport numpy as np
import random as rd
import math
import C_GenericAlgorithm as ga


" constants "
directions = {"TL":[-1,-1], "L":[0,-1], "BL":[1,-1], "B":[1,0], "BR":[1,1], "R":[0,1], "TR":[-1,1]}
OPPOSED = {"BR":"TL", "TL":"BR", "R":"L", "L":"R", "BL":"TR", "TR":"BL"}
I = 6
J = 7
PLAYER_1 = 1 # grid.player
PLAYER_2 = 2
EMPTY = 0
LIMIT = 3
cdef int CA1 = 100000
cdef int CA2 = 0
cdef int CA3 = 8000
cdef int CA4 = 7000
cdef int CA5 = 4000
cdef int CA6 = 3000
cdef int CA7 = 1000
cdef public int[7] MATRIX_COEFFS = [CA1,CA2,CA3,CA4,CA5,CA6,CA7]


" additional info "
# Player names convention : (may vary in the future)
    # ** : coin for player 1
    # 00 : coin for player 2
    # .. : empty cell """
    
    
" issues "
### generate_cell_dictionnaries
### self.cv


cdef class Grid:
    """ A usefull class to manipulate the interesting empty locations in the grid """

    #cdef public Cell[6][7] matrix
    cdef public list matrix
    cdef public Connect4 c4
    cdef public int player
    cdef public int weight_2
    cdef public int[7] matrix_coeff
    cdef public int CA1
    cdef public int CA2
    cdef public int CA3
    cdef public int CA4
    cdef public int CA5
    cdef public int CA6
    cdef public int CA7
    def __init__(self, Connect4 c4, int player, matrix_coeff):
        """ c4 <class> Connect4
            player <class> int <in> [PLAYER_1, PLAYER_2] """

        self.matrix = [[None,None,None,None,None,None,None],[None,None,None,None,None,None,None],[None,None,None,None,None,None,None],[None,None,None,None,None,None,None],[None,None,None,None,None,None,None],[None,None,None,None,None,None,None]]

        self.c4 = c4
        self.player = player    # which player has to make a choice (see the player names convention)
        self.weight_2 = 0
        self.matrix_coeff = matrix_coeff
        self.CA1 = matrix_coeff[0]
        self.CA2 = matrix_coeff[1]
        self.CA3 = matrix_coeff[2]
        self.CA4 = matrix_coeff[3]
        self.CA5 = matrix_coeff[4]
        self.CA6 = matrix_coeff[5]
        self.CA7 = matrix_coeff[6]


    def generate_cell_dictionary(self):
        """ Considers the empty locations in the grid directly connected to the already existing coins and generates a Cell
            object for each one of them. Then, the function creates an Alignment object for each possible interesting
            directions of each Cell object and stores the results in their respective attribute "adjacent_alignments_dico"
            with the key being the considered direction. Eventually the resulting Cell objects are stored in the self.matrix at
            their specific locations """
        cdef int i = 0
        cdef int i_right_column = 0
        cdef int i_left_column = 0
        for j in range(J):
            if not self.c4.column_is_full(j):
                i = self.c4.free_slots[j] - 1
                if j < J-1:
                    i_right_column = self.c4.free_slots[j+1] - 1
                    i_min_1 = min(i, i_right_column)
                if j > 0:
                    i_left_column = self.c4.free_slots[j-1] - 1
                    i_min_2 = min(i, i_left_column)
                if 0 < j < J-1:
                    i_min = min(i_right_column, i_left_column)
                    i_min = min(i_min, i)
                elif j==0:
                    i_min = min(i_right_column, i)
                elif j == J-1:
                    i_min = min(i_left_column, i)
                for k in range(i + 1 - i_min):
                    cell = Cell(i_min + k, j, self.c4, self.player, self.matrix_coeff)
                    cell.evaluate_adjacent_alignments()
                    self.matrix[i_min + k][j] = cell


    cdef int weight_grid(self):
        """ Updates the weight of the grid with regard to the attribute player """
        
        for i in range(6):
            for j in range(7):
                if self.matrix[i][j]:
                    self.matrix[i][j].main_weight()
                    #print([i,j], self.matrix[i][j].weight)  ################
                    self.weight_2 = self.weight_2 + self.matrix[i][j].weight
                    #print(self.weight_2)
        return 0


    cdef int differentiate_weight(self, Grid grid2):
        """ Takes into account the current score of the opponent by subtracting his score from the player's one
            grid2 <class> __main__.Grid """
        self.weight_2 = self.weight_2 - grid2.weight_2


cdef class Cell(Grid):
    """ A class to store the alignments around the free locations of the grid interesting for the self.player """
    cdef public int i
    cdef public int j
    cdef dict adjacent_alignments_dico
    cdef public int weight
    def __init__(self, int i, int j, Connect4 c4, int player, matrix_coeff):
        """ i,j <class> int
            c4 <class> Connect4
            player <class> int <in> [PLAYER_1, PLAYER_2] """
        cdef int[7] m_c = matrix_coeff
        super().__init__(c4, player, m_c)
        self.i = i
        self.j = j
        self.adjacent_alignments_dico = {}
        self.weight = 0
        # self.cv = 1  #on compte la cellule actuelle
        
        
    cdef bint check_player(self, int i, int j):
        """ Checks whether the location at [i,j] is a coin owned by the player or not
            i,j <class> int """

        return self.c4.grid[i][j] == self.player


    cdef int evaluate_adjacent_alignments(self):
        """ Determines the friendly alignments in every possible directions around the cell """
        cdef int i = self.i
        cdef int j = self.j
        possible_directions = directions.copy()

        # the next lines will determine the possible directions to check for alignments

        def delete_aux(dir_list):
            cdef str dir = ""
            for k in range(5):
             if dir_list[k] == None:
                continue
             else:
                dir = dir_list[k]
                del possible_directions[dir]

        if i == 0:
            if j == 0:
                delete_aux(["BL", "L", "TL", "TR", None])
            elif j == J-1:
                delete_aux(["TL", "TR", "R", "BR", None])
            else:
                delete_aux(["TL", "TR", None, None, None])
        if i == I-1:
            if j == 0:
                delete_aux(["TL", "L", "BL", "B", "BR"])
            elif j == J-1:
                delete_aux(["BL", "B", "BR", "R", "TR"])
            else:
                delete_aux(["BL", "B", "BR", None, None])

        # now we can identify the alignements in each possible directions

        for dir in possible_directions:
            alignment = Alignment([i,j])
            di, dj = possible_directions[dir]
            new_i, new_j = i + di, j + dj
            while self.is_in_grid([new_i,new_j]):
                if self.check_player(new_i, new_j):
                    alignment.aligned_coins = alignment.aligned_coins + 1
                else:
                    alignment.stop = [new_i, new_j]
                    alignment.stop_type = self.c4.grid[new_i][new_j]
                    break
                new_i += di
                new_j += dj
            self.adjacent_alignments_dico[dir] = alignment
        return 0


    cdef bint is_in_grid(self, loc):
        """ Evaluates whether the location is in the grid or not
            loc <class> list <form> [i_coordinate,j_coordinate] """
        cdef int i = loc[0]
        cdef int j = loc[1]
        return (0 <= i < I) and (0 <= j < J)


    def opposed_direction(self, dir):
        """ Returns the opposite direction of the dir argument
            dir <class> str <in> ["TL", "L", "BL", "BR", "R", "TR"] """
        
        return OPPOSED[dir]


    # def update_weight(self, weight):
    #     """ Updates the cell's weight
    #         weight <class> int """
    #     
    #     self.weight = self.weight + weight


    cdef bint check_combo(self,dir):
        """ Detects the presence of a combo around the cell. For instance, if the cell has a coin on its right and one on its
            left, then by putting a coin at its location the player achieves an alignment of three coins and this
            configuration should be understood as a potential alignment of three coins instead of a potential alignment of two
            coins in each of these directions
            dir <class> str <in> ["TL", "L", "BL", "BR", "R", "TR"] """
        cdef str new_dir = self.opposed_direction(dir)
        if new_dir in self.adjacent_alignments_dico :
            return (self.adjacent_alignments_dico[dir].aligned_coins != 0) and (self.adjacent_alignments_dico[new_dir].aligned_coins != 0)
        return False     


    cdef int combo(self, str dir, str new_dir):
        """ The part related to the treatment of combos. Consideres a pair of directions : one (dir) and its opposite
            (new_dir)
            dir, new_dir <class> str <in> ["TL", "L", "BL", "BR", "R", "TR"] """
        
        # self.count_cv()
        coins_dir = self.adjacent_alignments_dico[dir].aligned_coins
        coins_new_dir = self.adjacent_alignments_dico[new_dir].aligned_coins
        total_coins = coins_dir + coins_new_dir
        if total_coins >= 3:
            self.weight_cell(3)
        elif total_coins == 2:
            if self.adjacent_alignments_dico[dir].stop_type == EMPTY:
                self.weight_cell(2)
            elif self.adjacent_alignments_dico[new_dir].stop_type == EMPTY:
                self.weight_cell(2)
        return 0
    
    
    cdef bint enough_room(self, int[2] loc, str dir):
        """ Determines the number of empty locations in a line directed by the considered direction and comprising the occupied 
            location at loc (c.f. below weight_one_direction method, section coins == 1)
            Created to avoid taking into account the contribution of blocked alignments of one friendly coin when
            attributing the cell's weight
            loc <class> list <form> [i_coordinate, j_coordinate]
            dir <class> str <in> ["TL", "L", "BL", "BR", "R", "TR"] """

        cdef int di = directions[dir][0]
        cdef int dj = directions[dir][1]
        cdef int empty_loc_in_dir = 0
        cdef int new_i = loc[0] + di
        cdef int new_j = loc[1] + dj
        while self.is_in_grid([new_i, new_j]) and self.c4.grid[new_i][new_j] == EMPTY:
            empty_loc_in_dir += 1
            new_i += di
            new_j += dj
        
        cdef int empty_loc_in_opposed_dir = 1    # the one occupied by the Cell object studied in the weight_one_direction method (self)
        new_i, new_j = loc[0] - 2*di, loc[1] - 2*dj
        while self.is_in_grid([new_i, new_j]) and self.c4.grid[new_i][new_j] == EMPTY:
            empty_loc_in_opposed_dir += 1
            new_i -= di
            new_j -= dj
            
        return empty_loc_in_opposed_dir + empty_loc_in_dir >= 3
        

    cdef int weight_one_direction(self, dir):
        """ The part related to the treatment of the situations with no combo
            dir <class> str <in> ["TL", "L", "BL", "BR", "R", "TR"] """
        
        # self.count_cv()
        coins = self.adjacent_alignments_dico[dir].aligned_coins
        
        if coins == 3:
            self.weight_cell(3)
            
        if coins == 2:
            if self.adjacent_alignments_dico[dir].stop_type == EMPTY:
               self.weight_cell(2)
            
            else:
                new_dir = self.opposed_direction(dir)
                di, dj = directions[new_dir][0], directions[new_dir][1]
                new_i, new_j = self.i + di, self.j + dj
                if self.is_in_grid([new_i,new_j]):
                    if self.adjacent_alignments_dico[new_dir].stop_type == EMPTY or not self.adjacent_alignments_dico[new_dir].stop_type :
                        self.weight_cell(2)
        
        if coins == 1:
            di, dj = directions[dir][0], directions[dir][1]
            coin_i, coin_j = self.i + di, self.j + dj
            if self.enough_room([coin_i, coin_j], dir):
                self.weight_cell(1)
        return 0


    def main_weight(self):
        """ The main method that assesses which method to use : combo or weight_one_direction """
        
        dico = self.adjacent_alignments_dico
        new_dico = {"BR":True, "TL":True, "R":True, "L":True, "BL":True, "TR":True, "B": True}
        
        for dir in new_dico:
            if dir in dico:
                if dir == "B":
                    coins = dico["B"].aligned_coins
                    empty_loc_in_column = self.c4.free_slots[self.j]
                    if coins + empty_loc_in_column >= 4:
                        self.weight_cell(coins)
                else : 
                    if new_dico[dir]:   # if this location has not been explored yet
                        new_dico[dir]= False
                        if self.check_combo(dir):
                            new_dir = self.opposed_direction(dir)
                            new_dico[new_dir] = False
                            self.combo(dir, new_dir)
                        else:
                            self.weight_one_direction(dir)

    cdef int count_cv(self):
        """ Counts the number of empty cells in the column from the lowest to the current one """
        
        self.generate_cell_dictionary()
        cdef int cv = 1
        for i in range(self.i + 1, 6):
            if  type(self.matrix[i][self.j]) == Cell:  # None in matrix[i][j] means that there is a coin at [i,j]
                cv += 1
            else :
                break
        return cv


    cdef int weight_cell(self, coins):
        """ Determines the weight of a cell depending on its cv. Coins refers to the number of aligned coins
            coins <class> int <in> [1, 2, 3] """
        
        cv = self.count_cv()
        #cv = self.cv
        if coins == 1:
            if cv == 1:
                self.weight += self.CA6
            else :
                self.weight += self.CA7
        elif coins == 2:
            if cv == 1:
                self.weight += self.CA4
            elif cv == 2:
                self.weight += self.CA5
            else :
                self.weight += self.CA6
        elif coins == 3:
            if cv == 1:
                self.weight += self.CA1
            elif cv == 2:
                self.weight += self.CA2
            elif cv == 3 :
                self.weight += self.CA3
            else :
                self.weight += self.CA4
        return 0


cdef class Alignment:
    """ When a Cell object needs to check the number of friendly aligned coins in a given direction, it stores the results in
        an Alignment object and adds an entry in its "adjacent_alignments_dico" attribute, with the key refering to the
        considered direction and the argument being the generated Alignment object """

    cdef public int[2] start
    cdef public int[2] stop
    cdef public int stop_type
    cdef public int aligned_coins
    cdef public int c
    def __init__(self, start):
        """ A modelization of an alignment, with a start at [i,j], a stop at [i', j'], an information about the type of the stop
            (if it is an empty cell (EMPTY), a terrain border (LIMIT) or a coin owned by the other player (ADV)) and the number
            of coins in the alignment
            start <class> list <form> [i_coordinate,j_coordinate] """

        self.start = start
        self.stop = [-15, -15]   # None if the limit of the alignment is a c4 limit
        self.stop_type = LIMIT
        self.aligned_coins = 0
        self.c = 0


cdef int other_player(int player):
    """ Returns the other player's ID """
    return 3 - player


cdef float ia_alignment_potential(game, int[7] coeffs):   #coeffs est la liste des coefficients
    """ The evaluation ia associated to the potential method """
    cdef int[7] cf = coeffs
    cdef Grid g = Grid(game, game.player, cf)
    cdef Grid g2 = Grid(game, other_player(game.player), cf)
    g.generate_cell_dictionary()
    g.weight_grid()
    g2.generate_cell_dictionary()
    g2.weight_grid()
    if g2.weight_2 >= 1000000 and g.weight_2 >= 1000000:
        return -1
    #print(g.weight_2, g2.weight_2)
    g.differentiate_weight(g2)
    #print(g.weight_2)
    cdef float w = g.weight_2
    w = w / 1000000
    #print(w)
    return w
    


def ia_pa_terminal_nodes(player, game, end, maxdepth, depth, coeffs):
    cdef int[7] cf = coeffs
    if maxdepth:                                  #maxdepth = True si on est depth = 0 (si on est en bas de l'arbre)
        if end:
            return player
        else:
            w = ia_alignment_potential(game, cf)
            #print(w)
            return w
    else:
        return player * (depth + 1)

def ia_pa(game, coeffs):
    return ga.alphabeta(-1, game, ga.TREE_DEPTH, -math.inf, math.inf, True, ia_pa_terminal_nodes, coeffs)


ga.partie(ia_pa, [100000, -6354, 6023, -1274, 3615, 642, 7991], ia_pa, [100000, 9345, -1411, 6307, 2381, 7656, -811])