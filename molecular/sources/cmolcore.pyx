#cython: profile=False
#cython: boundscheck=False
#cython: cdivision=True

#NOTE: order of slow fonction to be optimize/multithreaded: kdtreesearching , kdtreecreating , linksolving 

cimport cython
from time import clock
from cython.parallel import parallel,prange
from libc.stdlib cimport malloc , realloc, free , rand , srand, abs


cdef extern from "stdlib.h":
    ctypedef void const_void "const void"
    void qsort(void *base, int nmemb, int size,int(*compar)(const_void *, const_void *)) nogil

    
cdef float fps = 0
cdef int substep = 0
cdef float deltatime = 0
cdef int parnum = 0
cdef int psysnum = 0
cdef int cpunum = 0
cdef int newlinks = 0
cdef int totallinks = 0
cdef int totaldeadlinks = 0
cdef int deadlinks = 0
cdef Particle *parlist
cdef Particle *parlistcopy
cdef ParSys *psys
cdef KDTree *kdtree = <KDTree *>malloc( 1 * cython.sizeof(KDTree) )

cpdef init(importdata):
    global fps
    global substep
    global deltatime
    global parnum
    global parlist
    global parlistcopy
    global kdtree
    global psysnum
    global psys
    global cpunum
    global newlinks
    global totallinks
    global totaldeadlinks
    global deadlinks
    cdef int i
    cdef int ii

    newlinks = 0
    totallinks = 0
    totaldeadlinks = 0
    deadlinks = 0
    fps = float(importdata[0][0])
    substep = int(importdata[0][1])
    deltatime = (fps * (substep +1))
    psysnum = importdata[0][2]
    parnum = importdata[0][3]
    cpunum = importdata[0][4]
    print "  Number of cpu's used:",cpunum
    psys = <ParSys *>malloc( psysnum * cython.sizeof(ParSys) )
    parlist = <Particle *>malloc( parnum * cython.sizeof(Particle) )
    parlistcopy = <Particle *>malloc( parnum * cython.sizeof(Particle) )
    cdef int jj = 0
    #printdb(47)
    for i in xrange(psysnum):
        psys[i].id = i
        psys[i].parnum = importdata[i+1][0]
        psys[i].particles = <Particle *>malloc( psys[i].parnum * cython.sizeof(Particle) )
        psys[i].particles = &parlist[jj]
        for ii in xrange(psys[i].parnum):
            parlist[jj].id = jj
            parlist[jj].loc[0] = importdata[i + 1][1][(ii * 3)]
            parlist[jj].loc[1] = importdata[i + 1][1][(ii * 3) + 1]
            parlist[jj].loc[2] = importdata[i + 1][1][(ii * 3) + 2]
            parlist[jj].vel[0] = importdata[i + 1][2][(ii * 3)]
            parlist[jj].vel[1] = importdata[i + 1][2][(ii * 3) + 1]
            parlist[jj].vel[2] = importdata[i + 1][2][(ii * 3) + 2]
            parlist[jj].size = importdata[i + 1][3][ii]
            parlist[jj].sqsize = sq_number(importdata[i + 1][3][ii])
            parlist[jj].mass = importdata[i + 1][4][ii]
            parlist[jj].state = importdata[i + 1][5][ii]
            psys[i].selfcollision_active = importdata[i + 1][6][0]
            psys[i].othercollision_active = importdata[i + 1][6][1]
            psys[i].collision_group = int(importdata[i + 1][6][2])
            psys[i].friction = importdata[i + 1][6][3]
            psys[i].links_active = importdata[i + 1][6][4]
            psys[i].link_length = importdata[i + 1][6][5]
            psys[i].link_max = importdata[i + 1][6][6]
            psys[i].link_tension = importdata[i + 1][6][7]
            psys[i].link_tensionrand = importdata[i + 1][6][8]
            psys[i].link_stiff = importdata[i + 1][6][9] * 0.5
            psys[i].link_stiffrand = importdata[i + 1][6][10]
            psys[i].link_stiffexp = importdata[i + 1][6][11]
            psys[i].link_damp = importdata[i + 1][6][12]
            psys[i].link_damprand = importdata[i + 1][6][13]
            psys[i].link_broken = importdata[i + 1][6][14]
            psys[i].link_brokenrand = importdata[i + 1][6][15]
            psys[i].link_estiff = importdata[i + 1][6][16] * 0.5
            psys[i].link_estiffrand = importdata[i + 1][6][17]
            psys[i].link_estiffexp = importdata[i + 1][6][18]
            psys[i].link_edamp = importdata[i + 1][6][19]
            psys[i].link_edamprand = importdata[i + 1][6][20]
            psys[i].link_ebroken = importdata[i + 1][6][21]
            psys[i].link_ebrokenrand = importdata[i + 1][6][22]
            psys[i].relink_group = int(importdata[i + 1][6][23])
            psys[i].relink_chance = importdata[i + 1][6][24]
            psys[i].relink_chancerand = importdata[i + 1][6][25]
            psys[i].relink_max = importdata[i + 1][6][26]
            psys[i].relink_tension = importdata[i + 1][6][27]
            psys[i].relink_tensionrand = importdata[i + 1][6][28]
            psys[i].relink_stiff = importdata[i + 1][6][29] * 0.5
            psys[i].relink_stiffexp = importdata[i + 1][6][30]
            psys[i].relink_stiffrand = importdata[i + 1][6][31]
            psys[i].relink_damp = importdata[i + 1][6][32]
            psys[i].relink_damprand = importdata[i + 1][6][33]
            psys[i].relink_broken = importdata[i + 1][6][34]
            psys[i].relink_brokenrand = importdata[i + 1][6][35]
            psys[i].relink_estiff = importdata[i + 1][6][36] * 0.5
            psys[i].relink_estiffexp = importdata[i + 1][6][37]
            psys[i].relink_estiffrand = importdata[i + 1][6][38]
            psys[i].relink_edamp = importdata[i + 1][6][39]
            psys[i].relink_edamprand = importdata[i + 1][6][40]
            psys[i].relink_ebroken = importdata[i + 1][6][41]
            psys[i].relink_ebrokenrand = importdata[i + 1][6][42]
            
            parlist[jj].sys = &psys[i]
            parlist[jj].collided_with = <int *>malloc( 1 * cython.sizeof(int) )
            parlist[jj].collided_num = 0
            parlist[jj].links = <Links *>malloc( 1 * cython.sizeof(Links) )
            parlist[jj].links_num = 0
            parlist[jj].links_activnum = 0
            parlist[jj].link_with = <int *>malloc( 1 * cython.sizeof(int) )
            parlist[jj].link_withnum = 0
            jj += 1
            
    jj = 0
    #printdb(115)
    KDTree_create_nodes(kdtree,parnum)
    #printdb(117)
    with nogil:
        for i in prange(parnum,schedule='dynamic',chunksize=10,num_threads=cpunum):
            parlistcopy[i] = parlist[i]
    #printdb(119)
    KDTree_create_tree(kdtree,parlistcopy,0,parnum - 1,0,-1,0,1)
    #printdb(120)
    with nogil:
        for i in prange(kdtree.thread_index,schedule='dynamic',chunksize=10,num_threads=cpunum):
            KDTree_create_tree(kdtree,parlistcopy,kdtree.thread_start[i],kdtree.thread_end[i],kdtree.thread_name[i],kdtree.thread_parent[i],kdtree.thread_depth[i],0)
    #printdb(121)
    with nogil:
        for i in prange(parnum,schedule='dynamic',chunksize=10,num_threads=cpunum):
            if parlist[i].sys.links_active == 1:
                KDTree_rnn_query(kdtree,&parlist[i],parlist[i].loc,parlist[i].sys.link_length)
    #printdb(122)
    for i in xrange(parnum):
        #printdb(123)
        create_link(parlist[i].id,parlist[i].sys.link_max)
        if parlist[i].neighboursnum > 1:
            free(parlist[i].neighbours)
        parlist[i].neighboursnum = 0
        #printdb(125)
    #printdb(126)
    #testkdtree(3)
    totallinks += newlinks
    print "  New links created: ",newlinks
    return parnum
    
    
cdef void printdb (int linenumber, text = ""):
    cdef int dbactive = 1
    if dbactive == 1:
        print(linenumber)

cdef testkdtree(int verbose = 0):
    global kdtree
    global parnum
    if verbose >= 3:
        print("RootNode:",kdtree.root_node[0].index)
        for i in xrange(parnum):
            print("Parent",kdtree.nodes[i].index,"Particle:",kdtree.nodes[i].particle[0].id)
            print("    Left",kdtree.nodes[i].left_child[0].index)
            print("    Right",kdtree.nodes[i].right_child[0].index)

    cdef float a[3]
    a[0] = 0
    a[1] = 0
    a[2] = 0
    cdef Particle *b
    b = <Particle *>malloc( 1 * cython.sizeof(Particle) )
    if verbose >= 1:
        print("start searching")
    KDTree_rnn_query(kdtree,b,a,2)
    output = []
    if verbose >= 2:
        print("Result")
        for i in xrange(b[0].neighboursnum):
            print(" Query Particle:",parlist[b[0].neighbours[i]].id)
    if verbose >= 1:
        print("number of particle find:",b[0].neighboursnum)
    free(b)
    
    
cpdef simulate(importdata):
    global kdtree
    global parlist
    global parlistcopy
    global parnum
    global psysnum
    global psys
    global cpunum
    global deltatime
    global newlinks
    global totallinks
    global totaldeadlinks
    global deadlinks
    
    cdef int i
    cdef int ii
    cdef float zeropoint[3]
    newlinks = 0
    deadlinks = 0
    #printdb(170)
    #print("start simulate")
    #stime2 = clock()
    #stime = clock()
    update(importdata)
    #print("update time", clock() - stime,"sec")
    #stime = clock()
    #printdb(175)
    
    with nogil:
        for i in prange(parnum,schedule='dynamic',chunksize=10,num_threads=cpunum):
            parlistcopy[i] = parlist[i]
    #printdb(178)   
    KDTree_create_tree(kdtree,parlistcopy,0,parnum - 1,0,-1,0,1)
    #printdb(182)
    with nogil:
        for i in prange(kdtree.thread_index,schedule='dynamic',chunksize=10,num_threads=cpunum):
            KDTree_create_tree(kdtree,parlistcopy,kdtree.thread_start[i],kdtree.thread_end[i],kdtree.thread_name[i],kdtree.thread_parent[i],kdtree.thread_depth[i],0)
    
    #print("create tree time", clock() - stime,"sec")
    #testkdtree(3)
    
    #cdef int *test
    #printdb(188)
    #print(parlist[1].loc[0],parlist[234].loc[0],parlist[836].loc[0])
    #print(parlist[1].loc[1],parlist[234].loc[1],parlist[836].loc[1])
    #print(parlist[1].loc[2],parlist[234].loc[2],parlist[836].loc[2])
    #stime = clock()
    with nogil:
        for i in prange(parnum,schedule='dynamic',chunksize=10,num_threads=cpunum):
            KDTree_rnn_query(kdtree,&parlist[i],parlist[i].loc,parlist[i].size * 2)
            
    #printdb(189)
    #print("neighbours time", clock() - stime,"sec")
    #stime = clock()


    for i in xrange(parnum):
        #printdb(190)
        collide(&parlist[i])
        #printdb(192)
        solve_link(&parlist[i])
        free(parlist[i].neighbours)
        parlist[i].neighboursnum = 0
        #printdb(194)
            
    
    #print("collide/solve link time", clock() - stime,"sec")
    #printdb(195)
    #stime = clock()
    exportdata = []
    parloc = []
    parvel = []
    parloctmp = []
    parveltmp = []
    #printdb(195)
    for i in xrange(psysnum):
        for ii in xrange(psys[i].parnum):
            parloctmp.append(psys[i].particles[ii].loc[0])
            parloctmp.append(psys[i].particles[ii].loc[1])
            parloctmp.append(psys[i].particles[ii].loc[2])
            parveltmp.append(psys[i].particles[ii].vel[0])
            parveltmp.append(psys[i].particles[ii].vel[1])
            parveltmp.append(psys[i].particles[ii].vel[2])
        parloc.append(parloctmp)  
        parvel.append(parveltmp)
        parloctmp = []
        parveltmp = [] 
    #printdb(198)
    
    #print "  New links at this frame: ",newlinks
    #print "  Broken links this frame: ",deadlinks
    totallinks += newlinks
    totaldeadlinks += deadlinks
    #print "  left: ",totallinks - totaldeadlinks," on ",totallinks  
    exportdata = [parloc,parvel,newlinks,deadlinks,totallinks,totaldeadlinks]
    #print("export time", clock() - stime,"sec")
    #print("all process time", clock() - stime2,"sec")
    return exportdata

cpdef memfree():
    global kdtree
    global psysnum
    global parnum
    global psys
    global parlist
    global parlistcopy
    global fps
    global substep
    cdef int i
    #printdb(200)
    fps = 0
    substep = 0
    deltatime = 0
    parnum = 0
    psysnum = 0
    cpunum = 0
    newlinks = 0
    totallinks = 0
    totaldeadlinks = 0
    deadlinks = 0
    #printdb(205)
    for i in xrange(parnum):
        if parnum > 1:
            if parlist[i].neighboursnum > 1:
                free(parlist[i].neighbours)
                parlist[i].neighboursnum = 0
            if parlist[i].collided_num > 1:
                free(parlist[i].collided_with)
                parlist[i].collided_num = 0
            if parlist[i].links_num > 1:
                free(parlist[i].links)
                parlist[i].links_num = 0
                parlist[i].links_activnum = 0
            if parlist[i].link_withnum > 1:
                free(parlist[i].link_with)
                parlist[i].link_withnum = 0
    #printdb(208) 
    for i in xrange(psysnum):
        if psysnum > 1:
            free(psys[i].particles)
    #printdb(210)
    if psysnum > 1:
        free(psys)
    #printdb(215)
    if parnum > 1:
        free(parlistcopy)
        free(parlist)
    #printdb(220)
    parnum = 0
    psysnum = 0
    #free(kdtree.thread_nodes)
    #free(kdtree.thread_start)
    #free(kdtree.thread_end)
    #free(kdtree.thread_name)
    #free(kdtree.thread_parent)
    #free(kdtree.thread_depth)
    #free(kdtree.nodes)
    #free(kdtree.root_node)
    #free(kdtree)
    
    
#@cython.cdivision(True)
cdef void collide(Particle *par):# nogil:
    global kdtree
    global deltatime
    global deadlinks
    cdef int *neighbours
    cdef Particle *par2
    cdef float stiff
    cdef float target
    cdef float sqtarget
    cdef float lenghtx
    cdef float lenghty
    cdef float lenghtz
    cdef float sqlenght
    cdef float lenght
    cdef float factor
    cdef float ratio1
    cdef float ratio2
    cdef float factor1
    cdef float factor2
    cdef float col_normal1[3]
    cdef float col_normal2[3]
    cdef float ypar_vel[3]
    cdef float xpar_vel[3]
    cdef float yi_vel[3]
    cdef float xi_vel[3]
    cdef float friction1
    cdef float friction2
    cdef int i
    cdef int check = 0
    cdef float Ua    
    cdef float Ub
    cdef float Cr
    cdef float Ma
    cdef float Mb
    cdef float Va
    cdef float Vb
    cdef float force1
    cdef float force2
    
    if  par.state >= 2:
        return
    if par.sys.selfcollision_active == False and par.sys.othercollision_active == False:
        return
    #printdb(282)
    #neighbours = KDTree_rnn_query(kdtree,par.loc,par.size * 2)
    neighbours = par.neighbours
    #printdb(284)
    #for i in xrange(kdtree.num_result):
    for i in xrange(par.neighboursnum):
        check = 0
        #printdb(287)
        if parlist[i].id == -1:
            check += 1
        #printdb(290)
        par2 = &parlist[neighbours[i]]
        #printdb(292)
        if par.id == par2.id:
            check += 10
        #printdb(295)
        if arraysearch(par2.id,par.collided_with,par.collided_num) == -1: 
        #if par2 not in par.collided_with:
            #printdb(298)
            if par2.sys.id != par.sys.id :
                #printdb(300)
                if par2.sys.othercollision_active == False or par.sys.othercollision_active == False:
                    #printdb(302)
                    check += 100
            if par2.sys.collision_group != par.sys.collision_group:
                #printdb(304)
                check += 1000
            if par2.sys.id == par.sys.id and par.sys.selfcollision_active == False:
                #printdb(308)
                check += 10000
            #printdb(310)
            stiff = deltatime
            target = (par.size + par2.size) * 0.999
            sqtarget = target * target
            #printdb(314)
            if check == 0 and par2.state <= 1 and arraysearch(par2.id,par.link_with,par.link_withnum) == -1 and arraysearch(par.id,par2.link_with,par2.link_withnum) == -1:
            #if par.state <= 1 and par2.state <= 1 and par2 not in par.link_with and par not in par2.link_with:
                #printdb(317)
                lenghtx = par.loc[0] - par2.loc[0]
                lenghty = par.loc[1] - par2.loc[1]
                lenghtz = par.loc[2] - par2.loc[2]
                sqlenght  = square_dist(par.loc,par2.loc,3)
                #printdb(322)
                if sqlenght != 0 and sqlenght < sqtarget:
                    lenght = sqlenght**0.5
                    factor = (lenght - target) / lenght
                    ratio1 = (par2.mass/(par.mass + par2.mass))
                    ratio2 = (par.mass/(par.mass + par2.mass))
                    

                    force1 = factor * ratio1 * stiff
                    force2 = factor * ratio2 * stiff
                    par.vel[0] -= lenghtx * force1
                    par.vel[1] -= lenghty * force1
                    par.vel[2] -= lenghtz * force1
                    par2.vel[0] += lenghtx * force2
                    par2.vel[1] += lenghty * force2
                    par2.vel[2] += lenghtz * force2
                    
                    
                    #printdb(336)

                    col_normal1[0] = (par2.loc[0] - par.loc[0]) / lenght
                    col_normal1[1] = (par2.loc[1] - par.loc[1]) / lenght
                    col_normal1[2] = (par2.loc[2] - par.loc[2]) / lenght
                    col_normal2[0] = col_normal1[0] * -1
                    col_normal2[1] = col_normal1[1] * -1
                    col_normal2[2] = col_normal1[2] * -1
                     
                    factor1 = dot_product(par.vel,col_normal1)      
                    
                    ypar_vel[0] = factor1 * col_normal1[0]
                    ypar_vel[1] = factor1 * col_normal1[1]
                    ypar_vel[2] = factor1 * col_normal1[2]
                    xpar_vel[0] = par.vel[0] - ypar_vel[0]
                    xpar_vel[1] = par.vel[1] - ypar_vel[1]
                    xpar_vel[2] = par.vel[2] - ypar_vel[2]
                    #printdb(352)
                    
                    factor2 = dot_product(par2.vel,col_normal2)
                    yi_vel[0] = factor2 * col_normal2[0]
                    yi_vel[1] = factor2 * col_normal2[1]
                    yi_vel[2] = factor2 * col_normal2[2]
                    xi_vel[0] = par2.vel[0] - yi_vel[0]
                    xi_vel[1] = par2.vel[1] - yi_vel[1]
                    xi_vel[2] = par2.vel[2] - yi_vel[2]
                    
                    """
                    Ua = factor1     
                    Ub = -factor2 
                    Cr = 1.0
                    Ma = par.mass
                    Mb = par2.mass     
                    Va = (Cr*Mb*(Ub-Ua)+Ma*Ua+Mb*Ub)/(Ma+Mb)
                    Vb = (Cr*Ma*(Ua-Ub)+Ma*Ua+Mb*Ub)/(Ma+Mb)
                    
                    #mula = 1
                    #mulb = 1
                    #Va = Va * (1 - Cr)
                    #Vb = Vb * (1 - Cr)
                    ypar_vel[0] = col_normal1[0] * Va
                    ypar_vel[1] = col_normal1[1] * Va
                    ypar_vel[2] = col_normal1[2] * Va
                    yi_vel[0] = col_normal1[0] * Vb
                    yi_vel[1] = col_normal1[1] * Vb
                    yi_vel[2] = col_normal1[2] * Vb
                    """

                    #printdb(381)
                    friction1 = 1 - ((par.sys.friction + par2.sys.friction ) * ratio1)
                    friction2 = 1 - ((par.sys.friction + par2.sys.friction ) * ratio2)
                    #xpar_vel[0] *= friction
                    #xpar_vel[1] *= friction
                    #xpar_vel[2] *= friction
                    #xi_vel[0] *= friction
                    #xi_vel[1] *= friction
                    #xi_vel[2] *= friction
                    
                    par.vel[0] = ypar_vel[0] + ((xpar_vel[0] * friction1) + ( xi_vel[0] * ( 1 - friction1)))
                    par.vel[1] = ypar_vel[1] + ((xpar_vel[1] * friction1) + ( xi_vel[1] * ( 1 - friction1)))
                    par.vel[2] = ypar_vel[2] + ((xpar_vel[2] * friction1) + ( xi_vel[2] * ( 1 - friction1)))
                    par2.vel[0] = yi_vel[0] + ((xi_vel[0] * friction2) + ( xpar_vel[0] * ( 1 - friction2)))
                    par2.vel[1] = yi_vel[1] + ((xi_vel[1] * friction2) + ( xpar_vel[1] * ( 1 - friction2)))
                    par2.vel[2] = yi_vel[2] + ((xi_vel[2] * friction2) + ( xpar_vel[2] * ( 1 - friction2)))
                    #printdb(396)
                    
         
                    
                    """
                    if abs(Va) < abs(((factor * ratio1) * stiff)):
                        par.vel[0] -= ((lenghtx * factor * ratio1) * stiff)
                        par.vel[1] -= ((lenghty * factor * ratio1) * stiff)
                        par.vel[2] -= ((lenghtz * factor * ratio1) * stiff)
                    if abs(Vb) < abs(((factor * ratio2) * stiff)):
                        par2.vel[0] += ((lenghtx * factor * ratio2) * stiff)
                        par2.vel[1] += ((lenghty * factor * ratio2) * stiff)
                        par2.vel[2] += ((lenghtz * factor * ratio2) * stiff)
                    """
                    
                    par2.collided_with[par2.collided_num] = par.id
                    par2.collided_num += 1
                    par2.collided_with = <int *>realloc(par2.collided_with,(par2.collided_num + 1) * cython.sizeof(int) )
                    if ((par.sys.relink_chance + par2.sys.relink_chance) / 2) > 0:
                        #printdb(405)
                        create_link(par.id,par.sys.link_max * 2,par2.id)

                    #printdb(416)
                #printdb(417)
            #printdb(418)
        #printdb(419)
    #free(neighbours)
    #free(par2)
    #printdb(422)


cdef void solve_link(Particle *par):# nogil:
    global parlist
    global deltatime
    global deadlinks
    cdef int i
    cdef float stiff
    cdef float damping
    cdef float timestep
    cdef float exp
    cdef Particle *par1
    cdef Particle *par2
    cdef float Loc1[3]
    cdef float Loc2[3]
    cdef float V1[3]
    cdef float V2[3]
    cdef float LengthX
    cdef float LengthY
    cdef float LengthZ
    cdef float Length
    cdef float Vx
    cdef float Vy
    cdef float Vz
    cdef float V
    cdef float ForceSpring
    cdef float ForceDamper
    cdef float ForceX
    cdef float ForceY
    cdef float ForceZ
    cdef float Force1[3]
    cdef float Force2[3]
    cdef float ratio1
    cdef float ratio2
    cdef int parsearch
    cdef int par2search
    #broken_links = []
    if  par.state >= 2:
        return
    for i in xrange(par.links_num):
        if par.links[i].start != -1:
            par1 = &parlist[par.links[i].start]
            par2 = &parlist[par.links[i].end]
            Loc1[0] = par1.loc[0]
            Loc1[1] = par1.loc[1]
            Loc1[2] = par1.loc[2]
            Loc2[0] = par2.loc[0]
            Loc2[1] = par2.loc[1]
            Loc2[2] = par2.loc[2]
            V1[0] = par1.vel[0]
            V1[1] = par1.vel[1]
            V1[2] = par1.vel[2]
            V2[0] = par2.vel[0]
            V2[1] = par2.vel[1]
            V2[2] = par2.vel[2]
            LengthX = Loc2[0] - Loc1[0]
            LengthY = Loc2[1] - Loc1[1]
            LengthZ = Loc2[2] - Loc1[2]
            Length = (LengthX**2 + LengthY**2 + LengthZ**2)**(0.5)
            if par.links[i].lenght != Length and Length != 0:
                if par.links[i].lenght > Length:
                    stiff = par.links[i].stiffness * deltatime
                    damping = par.links[i].damping
                    exp = par.links[i].exponent
                if par.links[i].lenght < Length:
                    stiff = par.links[i].estiffness * deltatime
                    damping = par.links[i].edamping
                    exp = par.links[i].eexponent
                Vx = V2[0] - V1[0]
                Vy = V2[1] - V1[1]
                Vz = V2[2] - V1[2]
                V = (Vx * LengthX + Vy * LengthY+Vz * LengthZ) / Length
                ForceSpring = ((Length - par.links[i].lenght)**(exp)) * stiff
                ForceDamper = damping * V
                ForceX = (ForceSpring + ForceDamper) * LengthX / Length
                ForceY = (ForceSpring + ForceDamper) * LengthY / Length
                ForceZ = (ForceSpring + ForceDamper) * LengthZ / Length
                Force1[0] = ForceX
                Force1[1] = ForceY
                Force1[2] = ForceZ
                Force2[0] = -ForceX
                Force2[1] = -ForceY
                Force2[2] = -ForceZ
                ratio1 = (par2.mass/(par1.mass + par2.mass))
                ratio2 = (par1.mass/(par1.mass + par2.mass))
                par1.vel[0] += Force1[0] * ratio1
                par1.vel[1] += Force1[1] * ratio1
                par1.vel[2] += Force1[2] * ratio1
                par2.vel[0] += Force2[0] * ratio2
                par2.vel[1] += Force2[1] * ratio2
                par2.vel[2] += Force2[2] * ratio2
                
                if Length > (par.links[i].lenght  * (1 + par.links[i].ebroken)) or Length < (par.links[i].lenght  * (1 - par.links[i].broken)):
                    par.links[i].start = -1
                    par.links_activnum -= 1
                    deadlinks += 1
                    parsearch = arraysearch(par2.id,par.link_with,par.link_withnum)
                    if parsearch != -1:
                        par.link_with[parsearch] = -1
                    par2search = arraysearch(par.id,par2.link_with,par2.link_withnum)
                    if par2search != -1:
                        par2.link_with[par2search] = -1
                    #broken_links.append(link)
                    #if par2 in par1.link_with:
                        #par1.link_with.remove(par2)
                    #if par1 in par2.link_with:
                        #par2.link_with.remove(par1)
                            
    #par.links = list(set(par.links) - set(broken_links))
    
    #free(par1)
    #free(par2)

    
cdef void update(data):
    global parlist
    global parnum
    global psysnum
    global psys
    cdef int i = 0
    cdef int ii = 0
    for i in xrange(psysnum):
        for ii in xrange(psys[i].parnum):
            psys[i].particles[ii].loc[0] = data[i][0][(ii * 3)]
            psys[i].particles[ii].loc[1] = data[i][0][(ii * 3) + 1]
            psys[i].particles[ii].loc[2] = data[i][0][(ii * 3) + 2]
            psys[i].particles[ii].vel[0] = data[i][1][(ii * 3)]
            psys[i].particles[ii].vel[1] = data[i][1][(ii * 3) + 1]
            psys[i].particles[ii].vel[2] = data[i][1][(ii * 3) + 2]
            if psys[i].particles[ii].state == 0 and data[i][2][ii] == 0:
                psys[i].particles[ii].state = data[i][2][ii] + 1
                #printdb(546)
                if psys[i].links_active == 1:
                    KDTree_rnn_query(kdtree,&psys[i].particles[ii],psys[i].particles[ii].loc,psys[i].particles[ii].sys.link_length)
                    create_link(psys[i].particles[ii].id,psys[i].link_max)
                    free(psys[i].particles[ii].neighbours)
                    psys[i].particles[ii].neighboursnum = 0
                #printdb(548)

            elif psys[i].particles[ii].state == 1 and data[i][2][ii] == 0:
                psys[i].particles[ii].state = 1

            else:
                psys[i].particles[ii].state = data[i][2][ii]
            psys[i].particles[ii].collided_with = <int *>realloc(psys[i].particles[ii].collided_with, 1 * cython.sizeof(int) )
            psys[i].particles[ii].collided_num = 0

    #printdb(558)
 
cdef void KDTree_create_nodes(KDTree *kdtree,int parnum):# nogil:
    cdef int i
    i = 2
    #print(parnum)
    while i < parnum:
        i = i * 2
        #print(i)
    kdtree.numnodes = i
    kdtree.nodes = <Node *>malloc( (kdtree.numnodes + 1) * cython.sizeof(Node) )
    kdtree.root_node = <Node *>malloc( 1 * cython.sizeof(Node) )
    for i in xrange(kdtree.numnodes):
        kdtree.nodes[i].index = i
        kdtree.nodes[i].name = -1
        kdtree.nodes[i].parent = -1
        kdtree.nodes[i].particle = <Particle *>malloc( 1 * cython.sizeof(Particle) )
        kdtree.nodes[i].left_child = <Node *>malloc( 1 * cython.sizeof(Node) )
        kdtree.nodes[i].right_child = <Node *>malloc( 1 * cython.sizeof(Node) )
        kdtree.nodes[i].left_child[0].index = -1
        kdtree.nodes[i].right_child[0].index = -1
    kdtree.nodes[kdtree.numnodes + 1].index = -1
    kdtree.nodes[kdtree.numnodes + 1].name = -1
    kdtree.nodes[kdtree.numnodes + 1].parent = -1
    kdtree.nodes[kdtree.numnodes + 1].particle = <Particle *>malloc( 1 * cython.sizeof(Particle) )
    kdtree.nodes[kdtree.numnodes + 1].left_child = <Node *>malloc( 1 * cython.sizeof(Node) )
    kdtree.nodes[kdtree.numnodes + 1].right_child = <Node *>malloc( 1 * cython.sizeof(Node) )
    kdtree.nodes[kdtree.numnodes + 1].left_child[0].index = -1
    kdtree.nodes[kdtree.numnodes + 1].right_child[0].index = -1
    kdtree.thread_nodes = <int *>malloc( 128 * cython.sizeof(int) )
    kdtree.thread_start = <int *>malloc( 128 * cython.sizeof(int) )
    kdtree.thread_end = <int *>malloc( 128 * cython.sizeof(int) )
    kdtree.thread_name = <int *>malloc( 128 * cython.sizeof(int) )
    kdtree.thread_parent = <int *>malloc( 128 * cython.sizeof(int) )
    kdtree.thread_depth = <int *>malloc( 128 * cython.sizeof(int) )
    return

   
cdef Node KDTree_create_tree(KDTree *kdtree,Particle *kdparlist,int start,int end,int name,int parent,int depth,int initiate)nogil:
    global parnum
    cdef int index
    cdef int len = (end - start) + 1
    #print("len:",len)
    if len <= 0:
        return kdtree.nodes[kdtree.numnodes + 1]
    cdef int axis
    cdef int k = 3
    axis = depth % k
    #printdb(590)
    if axis == 0:
        qsort(kdparlist + start,len,sizeof(Particle),compare_x)
    elif axis == 1:
        qsort(kdparlist + start,len,sizeof(Particle),compare_y)
    elif axis == 2:
        qsort(kdparlist + start,len,sizeof(Particle),compare_z)
    cdef int median = (start + end) / 2
    #printdb(598)
    if depth == 0:
            kdtree.thread_index = 0
            index = 0
    else:
        index = (parent * 2) + name
    if index > kdtree.numnodes:
        return kdtree.nodes[kdtree.numnodes + 1]
    #printdb(605)
    kdtree.nodes[index].name = name
    kdtree.nodes[index].parent = parent
    #printdb(607)
    if len >= 1 and depth == 0:
        kdtree.root_node[0] = kdtree.nodes[0]
    #printdb(610)
    #print("index",index)
    #print("num nodes",kdtree.numnodes)
    kdtree.nodes[index].particle[0] = kdparlist[median]
    #printdb(612)
    if parnum > 127:
        if depth == 4 and initiate == 1:
            kdtree.thread_nodes[kdtree.thread_index] = index
            kdtree.thread_start[kdtree.thread_index] = start
            kdtree.thread_end[kdtree.thread_index] = end
            kdtree.thread_name[kdtree.thread_index] = name
            kdtree.thread_parent[kdtree.thread_index] = parent
            kdtree.thread_depth[kdtree.thread_index] = depth
            #print(kdtree.nodes[index].index)
            kdtree.thread_index += 1
            return kdtree.nodes[index]
    kdtree.nodes[index].left_child[0] = KDTree_create_tree(kdtree,kdparlist,start,median - 1,1,index,depth + 1,initiate)
    #printdb(614)
    kdtree.nodes[index].right_child[0] = KDTree_create_tree(kdtree,kdparlist,median + 1,end,2,index,depth + 1,initiate)
    #printdb(616)
    return kdtree.nodes[index]


cdef int KDTree_rnn_query(KDTree *kdtree,Particle *par,float point[3],float dist)nogil:
    global parlist
    cdef float sqdist
    cdef int k 
    cdef int i
    par.neighboursnum = 0
    #printdb(639)
    #free(par.neighbours)
    #printdb(641)
    par.neighbours = <int *>malloc( 1 * cython.sizeof(int) )
    #printdb(643)
    par.neighbours[0] = -1
    #printdb(645)
    if kdtree.root_node[0].index != kdtree.nodes[0].index:
        par.neighbours[0] = -1
        par.neighboursnum = 0
        return -1
    else:
        sqdist = dist * dist
        KDTree_rnn_search(kdtree,&par[0],kdtree.root_node[0],point,dist,sqdist,3,0)


#@cython.cdivision(True)
cdef void KDTree_rnn_search(KDTree *kdtree,Particle *par,Node node,float point[3],float dist,float sqdist,int k,int depth)nogil:
    cdef int axis
    cdef float realdist
    #printdb(642)
    if node.index == -1:
        return
        
    cdef Particle tparticle = node.particle[0]
    
    axis = depth % k
    #printdb(649)
    if ((point[axis] - tparticle.loc[axis]) * (point[axis] - tparticle.loc[axis])) <= sqdist:
        realdist = square_dist(point,tparticle.loc,3)
        #printdb(652)
        if realdist <= sqdist:
            #printdb(654)
            par.neighbours[par.neighboursnum] = node.particle[0].id
            par.neighboursnum += 1
            par.neighbours = <int *>realloc(par.neighbours,(par.neighboursnum + 1) * cython.sizeof(int) )
            #printdb(658)

        #printdb(660)
        KDTree_rnn_search(kdtree,&par[0],node.left_child[0],point,dist,sqdist,3,depth + 1)
        #printdb(662)
        KDTree_rnn_search(kdtree,&par[0],node.right_child[0],point,dist,sqdist,3,depth + 1)
        #printdb(664)
    else:
        if point[axis] <= tparticle.loc[axis]:
            #printdb(667)
            KDTree_rnn_search(kdtree,&par[0],node.left_child[0],point,dist,sqdist,3,depth + 1)
        if point[axis] >= tparticle.loc[axis]:
            #printdb(670)
            KDTree_rnn_search(kdtree,&par[0],node.right_child[0],point,dist,sqdist,3,depth + 1)
    #printdb(672)
  
  
cdef void create_link(int par_id, int max_link, int parothers_id = -1):# nogil:
    #printdb(676)
    global kdtree
    global parlist
    global parnum
    global newlinks
    #printdb(680)
    cdef Links *link = <Links *>malloc( 1 * cython.sizeof(Links))
    #printdb(682)
    cdef int *neighbours
    cdef int ii
    cdef int neighboursnum
    cdef float rand_max = 32767 
    cdef Particle *par
    cdef Particle *par2
    cdef float stiffrandom
    cdef float damprandom
    cdef float brokrandom
    cdef float tension
    cdef float tensionrandom
    cdef float chancerdom
    cdef Particle *fakepar = <Particle *>malloc( 1 * cython.sizeof(Particle))
    par = &parlist[par_id]
    #printdb(693)
    if  par.state >= 2:
        return
    if par.links_activnum >= max_link:
        return
    if par.sys.links_active == 0:
        #printdb(699)
        #free(link)
        #free(par)
        #free(par2)
        #free(neighbours)
        return
    #printdb(705)
    if parothers_id == -1:
        #printdb(707)
        #KDTree_rnn_query(kdtree,&fakepar[0],par.loc,par.sys.link_length)
        #neighbours = fakepar[0].neighbours
        neighbours = par.neighbours
        neighboursnum = par.neighboursnum
        #printdb(709)
    else:
        #printdb(711)
        neighbours = <int *>malloc( 1 * cython.sizeof(int))
        neighbours[0] = parothers_id
        neighboursnum = 1
        
    #printdb(714)
    for ii in xrange(neighboursnum):
        #printdb(720)
        if parothers_id == -1:
            par2 = &parlist[neighbours[ii]]
            tension = (par.sys.link_tension + par2.sys.link_tension) / 2
        else:
            par2 = &parlist[neighbours[0]]
            tension = (par.sys.link_tension + par2.sys.link_tension) / 2
        if par.id != par2.id:
            #printdb(723)
            #arraysearch(par2.id,par.link_with,par.link_withnum)
            #printdb(725)
            if arraysearch(par.id,par2.link_with,par2.link_withnum) == -1 and par2.state <= 1 and par.state <= 1:
            #if par not in par2.link_with and par2.state <= 1 and par.state <= 1:
                #printdb(728)
                #printdb(729)
                link.start = par.id
                link.end = par2.id
                #printdb(732)
                
                if parothers_id == -1:
                    tensionrandom = (par.sys.link_tensionrand + par2.sys.link_tensionrand) / 2 * 2
                    srand(1)
                    tension = ((par.sys.link_tension + par2.sys.link_tension)/2) * ((((rand() / rand_max) * tensionrandom) - (tensionrandom / 2)) + 1)
                    srand(2)
                    link.lenght = ((square_dist(par.loc,par2.loc,3))**0.5) * tension
                    stiffrandom = (par.sys.link_stiffrand + par2.sys.link_stiffrand) / 2 * 2
                    link.stiffness = ((par.sys.link_stiff + par2.sys.link_stiff)/2) * ((((rand() / rand_max) * stiffrandom) - (stiffrandom / 2)) + 1)
                    srand(3)
                    link.estiffness = ((par.sys.link_estiff + par2.sys.link_estiff)/2) * ((((rand() / rand_max) * stiffrandom) - (stiffrandom / 2)) + 1)
                    srand(4)
                    link.exponent =  abs(int((par.sys.link_stiffexp + par2.sys.link_stiffexp) / 2))####
                    link.eexponent = abs(int((par.sys.link_estiffexp + par2.sys.link_estiffexp) / 2))####
                    damprandom = ((par.sys.link_damprand + par2.sys.link_damprand) / 2) * 2
                    link.damping = ((par.sys.link_damp + par2.sys.link_damp) / 2) * ((((rand() / rand_max) * damprandom) - (damprandom / 2)) + 1)
                    srand(5)
                    link.edamping = ((par.sys.link_edamp + par2.sys.link_edamp) / 2) * ((((rand() / rand_max) * damprandom) - (damprandom / 2)) + 1)
                    brokrandom = ((par.sys.link_brokenrand + par2.sys.link_brokenrand) / 2) * 2
                    srand(6)
                    link.broken = ((par.sys.link_broken + par2.sys.link_broken) / 2) * ((((rand() / rand_max) * brokrandom) - (brokrandom  / 2)) + 1)
                    srand(7)
                    link.ebroken = ((par.sys.link_ebroken + par2.sys.link_ebroken) / 2) * ((((rand() / rand_max) * brokrandom) - (brokrandom  / 2)) + 1)
                    #printdb(748)
                    par.links[par.links_num] = link[0]
                    par.links_num += 1
                    par.links_activnum += 1
                    #printdb(752)
                    par.links = <Links *>realloc(par.links,(par.links_num + 2) * cython.sizeof(Links) )
                    
                    #printdb(755)
                    par.link_with[par.link_withnum] = par2.id
                    par.link_withnum += 1
                    #printdb(758)
                    par.link_with = <int *>realloc(par.link_with,(par.link_withnum + 2) * cython.sizeof(int) )
                    
                    par2.link_with[par2.link_withnum] = par.id
                    par2.link_withnum += 1
                    #printdb(763)
                    par2.link_with = <int *>realloc(par2.link_with,(par2.link_withnum + 2) * cython.sizeof(int) )
                    newlinks += 1
                    #free(link)
                    #printdb(766)
                    
                if parothers_id != -1 and par.sys.relink_group == par2.sys.relink_group:
                    #printdb(769)
                    srand(8)
                    relinkrandom = (rand() / rand_max)
                    chancerdom = (par.sys.relink_chancerand + par2.sys.relink_chancerand) / 2 * 2
                    srand(9)
                    if relinkrandom <= ((par.sys.relink_chance + par2.sys.relink_chance) / 2) * ((((rand() / rand_max) * chancerdom) - (chancerdom / 2)) + 1):
                        tensionrandom = (par.sys.relink_tensionrand + par2.sys.relink_tensionrand) / 2 * 2
                        srand(10)
                        tension = ((par.sys.relink_tension + par2.sys.relink_tension)/2) * ((((rand() / rand_max) * tensionrandom) - (tensionrandom / 2)) + 1)
                        srand(11)
                        link.lenght = ((square_dist(par.loc,par2.loc,3))**0.5) * tension
                        stiffrandom = (par.sys.relink_stiffrand + par2.sys.relink_stiffrand) / 2 * 2
                        link.stiffness = ((par.sys.relink_stiff + par2.sys.relink_stiff)/2) * ((((rand() / rand_max) * stiffrandom) - (stiffrandom / 2)) + 1)
                        srand(12)
                        link.estiffness = ((par.sys.relink_estiff + par2.sys.relink_estiff)/2) * ((((rand() / rand_max) * stiffrandom) - (stiffrandom / 2)) + 1)
                        srand(13)
                        link.exponent = abs(int((par.sys.relink_stiffexp + par2.sys.relink_stiffexp) / 2))####
                        link.eexponent = abs(int((par.sys.relink_estiffexp + par2.sys.relink_estiffexp) / 2))####
                        damprandom = ((par.sys.relink_damprand + par2.sys.relink_damprand) / 2) * 2
                        link.damping = ((par.sys.relink_damp + par2.sys.relink_damp) / 2) * ((((rand() / rand_max) * damprandom) - (damprandom / 2)) + 1)
                        srand(14)
                        link.edamping = ((par.sys.relink_edamp + par2.sys.relink_edamp) / 2) * ((((rand() / rand_max) * damprandom) - (damprandom / 2)) + 1)
                        brokrandom = ((par.sys.relink_brokenrand + par2.sys.relink_brokenrand) / 2) * 2
                        link.broken = ((par.sys.relink_broken + par2.sys.relink_broken) / 2) * ((((rand() / rand_max) * brokrandom) - (brokrandom  / 2)) + 1)
                        srand(15)
                        link.ebroken = ((par.sys.relink_ebroken + par2.sys.relink_ebroken) / 2) * ((((rand() / rand_max) * brokrandom) - (brokrandom  / 2)) + 1)
                        par.links[par.links_num] = link[0]
                        par.links_num += 1
                        par.links_activnum += 1
                        par.links = <Links *>realloc(par.links,(par.links_num + 1) * cython.sizeof(Links) )
                        par.link_with[par.link_withnum] = par2.id
                        par.link_withnum += 1
                        par.link_with = <int *>realloc(par.link_with,(par.link_withnum + 1) * cython.sizeof(int) )
                        par2.link_with[par2.link_withnum] = par.id
                        par2.link_withnum += 1
                        par2.link_with = <int *>realloc(par2.link_with,(par2.link_withnum + 1) * cython.sizeof(int) )
                        newlinks += 1
                        #free(link)
    #free(neighbours)
    #free(link)
    #free(par)
    #free(par2)
            
cdef struct Links:
    float lenght
    int start
    int end
    float stiffness
    int exponent
    float damping
    float broken
    float estiffness
    int eexponent
    float edamping
    float ebroken
            
            
            
cdef struct KDTree:
    int numnodes
    #int num_result
    #int *result
    Node *root_node
    Node *nodes
    int thread_index
    int *thread_nodes
    int *thread_start
    int *thread_end
    int *thread_name
    int *thread_parent
    int *thread_depth


cdef struct Node:
    int index
    int name
    int parent
    float loc[3]
    Particle *particle
    Node *left_child
    Node *right_child
    

cdef struct ParSys:
    int id
    int parnum
    Particle *particles
    int selfcollision_active
    int othercollision_active
    int collision_group
    float friction
    int links_active
    float link_length
    int link_max
    float link_tension
    float link_tensionrand
    float link_stiff
    float link_stiffrand
    float link_stiffexp
    float link_damp
    float link_damprand
    float link_broken
    float link_brokenrand
    float link_estiff
    float link_estiffrand
    float link_estiffexp
    float link_edamp
    float link_edamprand
    float link_ebroken
    float link_ebrokenrand
    int relink_group
    float relink_chance
    float relink_chancerand
    int relink_max
    float relink_tension
    float relink_tensionrand
    float relink_stiff
    float relink_stiffexp
    float relink_stiffrand
    float relink_damp
    float relink_damprand
    float relink_broken
    float relink_brokenrand
    float relink_estiff
    float relink_estiffexp
    float relink_estiffrand
    float relink_edamp
    float relink_edamprand
    float relink_ebroken
    float relink_ebrokenrand

    
cdef struct Particle:
    int id
    float loc[3]
    float vel[3]
    float size
    float sqsize
    float mass
    float state
    ParSys *sys
    int *collided_with
    int collided_num
    Links *links
    int links_num
    int links_activnum
    int *link_with
    int link_withnum
    int *neighbours
    int neighboursnum



cdef int compare_x (const void *u, const void *v):# nogil:
    cdef float w = ((<Particle*>u)).loc[0] - ((<Particle*>v)).loc[0]
    if w < 0:
        return -1
    if w > 0:
        return 1
    return 0

    
cdef int compare_y (const void *u, const void *v):# nogil:
    cdef float w = ((<Particle*>u)).loc[1] - ((<Particle*>v)).loc[1]
    if w < 0:
        return -1
    if w > 0:
        return 1
    return 0
 
 
cdef int compare_z (const void *u, const void *v):# nogil:
    cdef float w = ((<Particle*>u)).loc[2] - ((<Particle*>v)).loc[2]
    if w < 0:
        return -1
    if w > 0:
        return 1
    return 0
    
cdef int compare_id (const void *u, const void *v):# nogil:
    cdef float w = ((<Particle*>u)).id - ((<Particle*>v)).id
    if w < 0:
        return -1
    if w > 0:
        return 1
    return 0   

  
cdef int arraysearch(int element,int *array,int len)nogil:
    cdef int i
    #printdb(939)
    for i in xrange(len):
        if element == array[i]:
            return i
    #printdb(943)
    return -1
cdef float fabs(float value)nogil:
    if value >= 0:
        return value
    if value < 0:
        return value * -1
 
cdef float sq_number(float val):# nogil:
    cdef float nearsq = 8
    while val > nearsq or val < nearsq / 2:
        if val > nearsq:
            nearsq = nearsq * 2
        elif val < nearsq / 2:
            nearsq = nearsq / 2
    return nearsq
    
#@cython.cdivision(True)  
cdef float square_dist(float point1[3],float point2[3],int k)nogil:
    cdef float sq_dist = 0
    for i in xrange(k):
        sq_dist += (point1[i] - point2[i]) * (point1[i] - point2[i])
    return sq_dist

    
cdef float dot_product(float u[3],float v[3])nogil:
    cdef float dot
    dot = (u[0] * v[0]) + (u[1] * v[1]) + (u[2] * v[2])
    return dot
