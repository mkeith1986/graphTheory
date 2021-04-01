#!/usr/bin/env python2
import pandas as pd
import matplotlib.pyplot as plt
from pandas.plotting import parallel_coordinates
import numpy as np
import collections
from matplotlib.colors import LinearSegmentedColormap
import networkx as nx
from networkx.algorithms import community
from networkx.algorithms import efficiency
from PIL import Image
import os
import sys
from operator import itemgetter
import datetime

def parallelPlot(M,axlabels,graphfile,pngout,figtit):
    groups,grp_labels = connectednessMtx(M,graphfile)
    
    data3 = pd.read_csv(graphfile)
    plt.subplots(figsize=(10, 15))
    parallel_coordinates(data3, 'conn_group', color=colorMap(len(groups)))
    
    plt.yticks(range(len(axlabels)), axlabels, fontsize=6)
    plt.tick_params(labelright=True)
    plt.title(figtit, fontsize=24)
    
    text = ''
    for grp in groups:
        text+="conn group "+str(grp)+": "+grp_labels[grp-1].replace('\n',' ')+'\n'
    plt.text(0.02, 0.04, text, fontsize=8, transform=plt.gcf().transFigure)
    
    plt.savefig(pngout, dpi=150)
    plt.close()
    
def printout(string,fout):
    print(string)
    fout.write(string+'\n')

def RSgraphs():
    printout("**RS**")
    
    # Create a version without heathers for the pmat and rmat
    
    # Remove the negative and non-significant correlations (threshold)
    
    # Re-order nodes by modular structure
    
    # Generate weighted matrix and graph
    
    # Binarize
    
    # Calculate graph metrics

def graphMetrics(graphfile,axlabels,fout):
    data3 = pd.read_csv(graphfile)
    
    # Get the list of connectedness values
    connectedness = []
    for val in data3.iloc[:,2]:
        connectedness+=[int(round(val))]
    
    # Get the list of starting roi
    roi1 = []
    for roi in data3.iloc[:,0]:
        roi1+=[axlabels[roi]]
    
    # Get the list of end roi
    roi2 = []
    for roi in data3.iloc[:,1]:
        roi2+=[axlabels[roi]]
    
    # Print the network metrics for the weighted graph
    df = pd.DataFrame({ 'from':roi1, 'to':roi2, 'value':connectedness})
    G = nx.from_pandas_edgelist(df, 'from', 'to', edge_attr=True, create_using=nx.Graph())
    printout(nx.info(G),fout)
    
    # Measures of functional segregation
    printout("Transitivity: "+str(nx.transitivity(G)),fout)
    communities_generator = community.girvan_newman(G)
    top_level_communities = next(communities_generator)
    next_level_communities = next(communities_generator)
    printout("Modular structure (Newman algorithm)",fout)
    modules = sorted(map(sorted, next_level_communities))
    i = 0
    for module in modules:
        printout("Module "+str(i)+':',fout)
        cnt = '['
        for node in module:
            cnt+=str(node)+','
        cnt = cnt[:-1]+']'
        printout(cnt,fout)
        i+=1
    printout("Modularity: "+str(community.quality.modularity(G,next_level_communities)),fout)
    
    if nx.is_connected(G):
        # Measures of functional integration
        printout("Characteristic path length: "+nx.average_shortest_path_length(G),fout)
    
        # Small-world coefficient (sigma) of the given graph
        # A graph is commonly classified as small-world if sigma>1
        sig = nx.algorithms.smallworld.sigma(G)
        printout("Sigma: "+str(sig),fout)
        if sig > 1:
            printout("Graph is a small world",fout)
        else:
            printout("Graph is NOT a small world",fout)
        
        # Small-world coefficient (omega) of the given graph
        # Between -1 and 1. Closer to 0, has small world characteristics
        # Closer to -1 G has a lattice shape
        # Closer to 1 G is a random graph
        printout("Omega: "+str(nx.algorithms.smallworld.omega(G)),fout)
    else:
        printout("Can't calculate characteristic path length nor small worldness measures (Graph is disconnected)",fout)
        
    # Measures that quantify centrality of individual brain regions or pathways
    printout("Top 10% nodes by degree:",fout)
    degree_dic = dict(G.degree(G.nodes()))
    nx.set_node_attributes(G, degree_dic, 'degree')
    sort_degree = sorted(degree_dic.items(), key=itemgetter(1), reverse=True)
    p = 10*len(sort_degree)/100
    for node,degree in sort_degree[:p]:
        printout("* "+node+": "+str(degree)+" connections",fout)
    # Eigenvector centrality
    # Is a node a hub and is it conencted to many hubs
    # Between 0 and 1, closer to 1 greater centrality
    # Which nodes can get information to any other nodes quickly
    printout("Top 10% nodes by centrality:",fout)
    eigenvector_dic = nx.eigenvector_centrality(G)
    nx.set_node_attributes(G, eigenvector_dic, 'eigenvector')
    sort_centrality = sorted(eigenvector_dic.items(), key=itemgetter(1), reverse=True)
    for node,centrality in sort_centrality[:p]:
        printout("* "+node+": "+str(centrality)+" centrality",fout)
    
    # Network density gives a quick sense of how closely knit the network is
    # Ratio of actual edges to all possible edges in the network
    # From 0 to 1. Closer to 1 is more dense.
    printout("Network density: "+str(nx.density(G)),fout)
    
    # Measures that test resilience of networks to insult
    printout("Calculating the degree histogram...",fout)
    degree_sequence = sorted([d for n, d in G.degree()], reverse=True)
    degreeCount = collections.Counter(degree_sequence)
    deg, cnt = zip(*degreeCount.items())
    fig, ax = plt.subplots()
    plt.bar(deg, cnt, width=0.80, color="b")
    plt.title("Degree Histogram")
    plt.ylabel("Count")
    plt.xlabel("Degree")
    ax.set_xticks([d + 0.4 for d in deg])
    ax.set_xticklabels(deg)
    plt.savefig(graphfile.replace(".csv","_dist.png"), dpi=150)
    plt.close()
    printout("done: "+graphfile.replace(".csv","_dist.png"),fout)
    r = nx.degree_assortativity_coefficient(G)
    # Networks with positive assortativity: have a resilient core of mutually inter-connected high-degree hubs. 
    # Networks with negative assortativity: have widely distributed and vulnerable high-degree hubs.
    printout
    # Can use this function to evaluate if the individual hubs may compromise the global structure if compromised:
    # networkx.algorithms.assortativity.average_neighbor_degree
            
def mergeHorizontalImgs(imgsList,output,rmorigs):
    imgs1 = [Image.open(i) for i in imgsList]
    min_img_height1 = min(i.height for i in imgs1)
    
    # Re-size images if necessary
    total_width1 = 0
    for i, img in enumerate(imgs1):
        # If the image is larger than the minimum height, resize it
        if img.height > min_img_height1:
            imgs1[i] = img.resize((min_img_height1, int(img.height / img.width * min_img_height1)), Image.ANTIALIAS)
        total_width1 += imgs1[i].width
    img_merge1 = Image.new(imgs1[0].mode, (total_width1, min_img_height1))
    
    # Concatenate horizontally
    x = 0
    for img in imgs1:
        img_merge1.paste(img, (x, 0))
        x += img.width
    
    img_merge1.save(output)
    if rmorigs:
        for img in imgsList:
            os.remove(img)

def mergeVerticalImgs(imgsList,output,rmorigs):
    imgs = [Image.open(i) for i in imgsList]
    min_img_width = min(i.width for i in imgs)
    
    # Re-size images if necessary
    total_height = 0
    for i, img in enumerate(imgs):
        # If the image is larger than the minimum width, resize it
        if int(img.height / img.width * min_img_width)>0 and img.width>min_img_width:
            imgs[i] = img.resize((min_img_width, int(img.height / img.width * min_img_width)), Image.ANTIALIAS)
        total_height += imgs[i].height
    img_merge = Image.new(imgs[0].mode, (min_img_width, total_height))
    
    # Concatenate vertically
    y = 0
    for img in imgs:
        img_merge.paste(img, (0, y))
        y += img.height
    
    img_merge.save(output)
    if rmorigs:
        for img in imgsList:
            os.remove(img)

def getConnections(roi_index,df):
    df1 = df[df['roi1'] == roi_index]
    c = []
    if not df1.empty:
        a = df1.iloc[:,1]
        for e in np.array(a):
            c+=[e]
            
    df2 = df[df['roi2'] == roi_index]
    if not df2.empty:
        b = df2.iloc[:,0]
        for e in np.array(b):
            c+=[e]
            
    return c

def addROI(roi_index,df,list1,axlabels,list2):
    # list2 will be the list of roi that are connected (a graph cluster)
    list2+=[axlabels[roi_index]]
    # Get the list of roi that are connected to roi_index
    roi_connections = getConnections(roi_index,df)
    list1.remove(roi_index)
    # Call recursively the function for each connected roi
    for conn in roi_connections:
        if conn in list1:
            list1 = addROI(conn,df,list1,axlabels,list2)
    return list1

def getClusterGroups(roi1,roi2,axlabels,df):
    groups = {}
    
    # Get the indices of all roi that have connections
    # Because in the df they appear with their index instead of roi name
    list1 = []
    for roi in np.unique(np.array(roi1+roi2)):
        list1+=[axlabels.index(roi)]
    
    # Group the roi in clusters where all the items are connected
    list2 = []
    while len(list1)>0:
        list1 = addROI(list1[0],df,list1,axlabels,list2)
        groups["Cluster "+str(len(groups.keys())+1)] = list2
        list2 = []
    
    return groups

def netgraphDSI(M,graphfile,axlabels,pngout,fout):
    data3 = pd.read_csv(graphfile)
   
    # Get the list of connectedness values
    connectedness = []
    for val in data3.iloc[:,2]:
        connectedness+=[int(round(val))]
    
    # Get the list of starting roi
    roi1 = []
    for roi in data3.iloc[:,0]:
        roi1+=[axlabels[roi]]
    
    # Get the list of end roi
    roi2 = []
    for roi in data3.iloc[:,1]:
        roi2+=[axlabels[roi]]
    
    # Obtain the different clusters of connected roi
    groups = getClusterGroups(roi1,roi2,axlabels,data3)
    clusters = sorted(groups.keys())
    
    # For each graph cluster get the list of nodes (roi1 and roi2) and their edge value (conn)
    grp_roi1 = {}
    grp_roi2 = {}
    grp_conn = {}
    for i in range(len(connectedness)):
        a = roi1[i]
        b = roi2[i]
        c = connectedness[i]
        for clust in clusters:
            # If the two roi belong to clust
            # The two should belong to the same cluster if grouped correctly
            if (a in groups[clust]) and (b in groups[clust]):
                if clust in grp_roi1.keys():
                    grp_roi1[clust]+=[a]  
                else: 
                    grp_roi1[clust] = [a]
                if clust in grp_roi2.keys():
                    grp_roi2[clust]+=[b]
                else:
                    grp_roi2[clust] = [b]
                if clust in grp_conn.keys():
                    grp_conn[clust]+=[c]  
                else:
                    grp_conn[clust] = [c]
    
    # Graph each cluster in a separate image
    # https://matplotlib.org/stable/tutorials/colors/colormaps.html
    cmap = plt.cm.winter
    
    # Get the number of hubs (subplots)
    # Get the number of lines and columns in the plot
    n_grps = len(grp_conn)
    printout("# subgraphs: "+str(n_grps),fout)
    if n_grps % 5 == 0:
        n_cols = 5
    elif n_grps % 4 == 0:
        n_cols = 4
    elif n_grps % 3 == 0:
        n_cols = 3
    elif n_grps % 2 == 0:
        n_cols = 2
    else:
        n_cols = 1
    printout("Grouping in "+str(n_cols)+" columns",fout)
    n_lines = n_grps/n_cols
    printout("and "+str(n_lines)+" lines",fout)
    test_imgs = []
    tmp_imgs = []
    
    for i in range(n_grps):
        plt.subplots(figsize=(10, 15))
        clust = clusters[i]
        df = pd.DataFrame({ 'from':grp_roi1[clust], 'to':grp_roi2[clust], 'value':grp_conn[clust]})
        G = nx.from_pandas_edgelist(df, 'from', 'to', edge_attr=True, create_using=nx.Graph())
        nx.draw(G, with_labels=True, node_color='skyblue', node_size=1400, edge_color=df['value'], edge_cmap=cmap)
        plt.savefig("test"+str(i)+".png", dpi=150)
        plt.close()
            
        # Merge the images to create a final PDF
        test_imgs+=["test"+str(i)+".png"]
        # Merge images horizontally
        if len(test_imgs)==n_cols:
            if n_lines==1:
                mergeHorizontalImgs(test_imgs,pngout,True)
            else:
                mergeHorizontalImgs(test_imgs,"tmp"+str(len(tmp_imgs))+".png",True)
                tmp_imgs+=["tmp"+str(len(tmp_imgs))+".png"]
            test_imgs = []
        # Merge horizontal images vertically as lines
        if len(tmp_imgs)==n_lines and n_lines>1:
            mergeVerticalImgs(tmp_imgs,pngout,True)

def DSIgraphFile(C,graphfile):   
    dim = len(C)
    fout = open(graphfile,'w')
    fout.write("roi1,roi2,conn\n")
    for i in range(dim):
        for j in range(i+1,dim):
            if C[i,j]>0:
                fout.write(str(i)+','+str(j)+','+str(C[i,j])+'\n')
    fout.close()

def connPlots(C,axlabels,pngout,figtit):
    # General plot properties
    plt.figure(figsize=(15, 10))
    dim = len(C)
    plt.xticks(range(dim), axlabels, rotation='vertical')
    plt.yticks(range(dim), axlabels)
    plt.grid(True, linestyle=':')
    plt.title(figtit, fontsize=24)
    
    # Colormap properties
    # https://matplotlib.org/stable/tutorials/colors/colormaps.html
    im1 = plt.imshow(C,cmap='gist_heat_r')
    
    plt.savefig(pngout, dpi=150)
    plt.close()

def connectedness(M,outfile):
    dim = len(M)
    C = np.zeros(shape=(dim,dim))
    for i in range(dim):
        for j in range(i+1,dim):
            avg = np.mean([M[i,j],M[j,i]])
            C[i,j] = avg
            C[j,i] = avg
    
    out = open(outfile,'w')
    for i in range(dim):
        for j in range(dim):
            out.write(str(C[i,j]))
            if j<dim-1:
                out.write(',')
        out.write('\n')
    out.close()
    
    return C

def DSIgraphs(fout,sbj_path,sbj_id,sess_id):
    # Load the connectivity matrix: contains just the values, no heather
    # One line per ROI, one column per ROI, values are connectivity
    printout("Loading connectivity matrix...",fout)
    M = np.loadtxt(open(sbj_path+"/matrix.csv","rb"), delimiter=",").astype(int)
    printout("done",fout)
    
    # Get the axes labels
    printout("\nGetting axes labels...",fout)
    k = open(sbj_path+"/tracto.csv",'r')
    axlabels = k.readline()[1:].replace('\n','').replace('_','').split(',')
    k.close()
    printout("done",fout)
    
    # Create connectedness matrix
    printout("\nCreating connectedness matrix...",fout)
    C = connectedness(M,sbj_path+"/connectedness.csv")
    printout("done: "+sbj_path+"/connectedness.csv",fout)
    
    # Plot the connectedness matrix
    printout("\nCreating the connectedness matrix plot...",fout)
    connPlots(C,axlabels,sbj_path+"/connectedness.png",sbj_id+'_'+sess_id)
    printout("done: "+sbj_path+"/connectedness.png",fout)
    
    ###############################################################
    # Reorder the nodes by modular structure and generate a plot
    # I have to find out how to do this part
    # Threshold? but what threshold to use?
    # Divide in groups? Then would have to maybe re-generate
    # the weighted graph
    # Other thing is that these matrices and metrics wont be
    # comparable until we use same set of roi in all sbjs/sess
    ###############################################################
    
    # Generate weighted graph
    printout("\nCreating weighted graph...",fout)
    netgraphDSI(C,sbj_path+"/connectedness_graph.csv",axlabels,sbj_path+"/connectedness_graph.png",fout)
    printout("done: "+sbj_path+"/connectedness_graph.png",fout)
    
    # Calculate the graph metrics
    printout("\nCalculating graph metrics...",fout)
    graphMetrics(sbj_path+"/connectedness_graph.csv",axlabels,fout)
    printout("done",fout)
    
def main():
    t1_date = str(datetime.date.today().strftime("%Y_%m_%d"))
    t1_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    t1_dt = t1_date+'_'+t1_time
                
    # python2 disp_res.py --sbj=KML --sess=day1 --pipe=rs
    sbj_id = ''
    sess_id = ''
    pipeline = ''
    sbj_path = ''
    log_path = ''
    for arg in sys.argv:
        if arg.startswith("--sbj="):
            sbj_id = arg.replace("--sbj=",'').upper()
        elif arg.startswith("--sess="):
            sess_id = arg.replace("--sess=",'').lower()
        elif arg.startswith("--pipe="):
            pipeline = arg.replace("--pipe=",'').lower()
        elif arg.startswith("--sbj_path="):
            sbj_path = arg.replace("--sbj_path=",'')
        elif arg.startswith("--log_path"):
            log_path = arg.replace("--log_path",'')
            
    if (sbj_id=='') or (sess_id=='') or (pipeline==''):
        sys.exit("Missing arguments")
    if sbj_path=='':
        sbj_path = "/group/agreenb/iPadStudy/keith/data/"+sbj_id+'/'+sess_id+'/'+pipeline
    if log_path=='':
        log_path = "/group/agreenb/iPadStudy/keith/Scripts/"+pipeline.upper()+"/graphs."+sbj_id
    fout = open(log_path,'w')
    printout("Processing "+sbj_id+'_'+sess_id+' '+pipeline,fout)
    printout("Output folder: "+sbj_path,fout)
    printout("Log file: "+log_path,fout)
    
    if pipeline.lower()=="rs":
        sbj_path+="/preproc/ts_mot"
        RSgraphs()
    elif pipeline.lower()=="dsi":
        DSIgraphs(fout,sbj_path,sbj_id,sess_id)
    else:
        sys.exit("Wrong pipeline")
    
    t2_date = str(datetime.date.today().strftime("%Y_%m_%d"))
    t2_time = str(datetime.datetime.today().strftime("%H:%M:%S"))
    t2_dt = t2_date+'_'+t2_time
    tdelta = str(datetime.datetime.strptime(t2_dt,"%Y_%m_%d_%H:%M:%S") - datetime.datetime.strptime(t1_dt,"%Y_%m_%d_%H:%M:%S"))
    printout("Execution time: "+tdelta,fout)
    
    fout.close()

if __name__ == "__main__":
        main()