module CrossSection

export CZcenterline, CUFSMtemplate


function CZcenterline(H,B1,D1,q1,B2,D2,q2,ri1,ri2,ri3,ri4,t)

	#Blatently pilfered from BWS CUFSM v5.01 Matlab download, thanks Ben.

	#Calculate centerline dimensions of Cees and Zees from outside dimensions
	#and inner radii.

	# BWS 2015
	# reference AISI Design Manual for the lovely corner radius calcs.
	# For template calc, convert outer dimensons and inside radii to centerline
	# dimensiosn throughout
	# convert the inner radii to centerline if nonzero
	if ri1==0
	    r1=0
	else
	    r1=ri1+t/2
	end

	if ri2==0
	    r2=0
	else
	    r2=ri2+t/2
	end

	if ri3==0
	    r3=0
	else
	    r3=ri3+t/2
	end

	if ri4==0
	    r4=0
	else
	    r4=ri4+t/2
	end

	h=H-t/2-r1-r3-t/2

	if D1==0
	    b1=B1-r1-t/2
	    d1=0
	else
	    b1=B1-r1-t/2-(r2+t/2)*tan(q1/2)
	    d1=(D1-(r2+t/2)*tan(q1/2))
	end

	if D2==0
	    b2=B2-r3-t/2
	    d2=0
	else
	    b2=B2-r3-t/2-(r4+t/2)*tan(q2/2)
	    d2=(D2-(r4+t/2)*tan(q2/2))
	end

	return h, b1, d1, q1, b2, d2, q2, r1, r2, r3, r4, t

end


function CUFSMtemplate(CorZ,h,b1,b2,d1,d2,r1,r2,r3,r4,q1,q2,t,nh,nb1,nb2,nd1,nd2,nr1,nr2,nr3,nr4,kipin,center)
	#Blatently pilfered from BWS CUFSM v5.01 Matlab download, thanks Ben.

	#BWS
	#August 23, 2000
	#2015 modification to allow for d1=d2=0 and creation of a track with same template
	#2015 addition to allow outer dimensions and inner radii to be used
	#2015 addition to control element discretization

	#CorZ=determines sign conventions for flange 1=C 2=Z
	if CorZ==2
		cz=-1;
	else
		cz=1;
	end
	#channel template

	#convert angles to radians
	q1=q1*π/180;
	q2=q2*π/180;
	#

	#if center is not 1 then outer dimensions and inner radii came in and these
	#need to be corrected to all centerline for the use of this template
	if center==1
	else
	    #label all the outer dimensions and inner radii
	    H=h;
	    B1=b1;
	    D1=d1;
	    ri1=r1;
	    ri2=r2;
	    B2=b2;
	    D2=d2;
	    ri3=r3;
	    ri4=r4;
	    h,b1,d1,q1,b2,d2,q2,r1,r2,r3,r4,t = CZcenterline(H,B1,D1,q1,B2,D2,q2,ri1,ri2,ri3,ri4,t);
	end


	#rest of the dimensions are "flat dimensions" and acceptable for modeling
	if (r1==0) & (r2==0) & (r3==0) & (r4==0)
	    if d1==0&d2==0
	        #track or unlipped Z with sharp corners
	        geom=[1 b1            0
	            2 0             0
	            3 0             h
	            4 cz*(b2)       h];
	        n=[nb1 nh nb2];
	    else
	        #lipped C or Z with sharp corners
	        geom=[1 b1+d1*cos(q1) d1*sin(q1)
	            2 b1            0
	            3 0             0
	            4 0             h
	            5 cz*(b2)       h
	            6 cz*(b2+d2*cos(q2)) h-d2*sin(q2)];
	        n=[nd1 nb1 nh nb2 nd2];
	    end
	else
	    if (d1==0) & (d2==0)
	        geom=[1 r1+b1                            0
	            2 r1                               0
	            3 0                                r1
	            4 0                                r1+h
	            5 cz*r3                               r1+h+r3
	            6 cz*(r3+b2)                            r1+h+r3];
	        n=[nb1 nr1 nh nr3 nb2];
	    else
	        geom=[1 r1+b1+r2*cos(π/2-q1)+d1*cos(q1) r2-r2*sin(π/2-q1)+d1*sin(q1)
	            2 r1+b1+r2*cos(π/2-q1)            r2-r2*sin(π/2-q1)
	            3 r1+b1                            0
	            4 r1                               0
	            5 0                                r1
	            6 0                                r1+h
	            7 cz*r3                               r1+h+r3
	            8 cz*(r3+b2)                            r1+h+r3
	            9 cz*(r3+b2+r4*cos(π/2-q2))            r1+h+r3-r4+r4*sin(π/2-q2)
	            10 cz*(r3+b2+r4*cos(π/2-q2)+d2*cos(q2)) r1+h+r3-r4+r4*sin(π/2-q2)-d2*sin(q2)];
	        n=[nd1 nr2 nb1 nr1 nh nr3 nb2 nr4 nd2];
	    end
	end
	#number of elements between the geom coordinates
	node=zeros(sum(n)+1,8)

	for i=1:size(geom)[1]-1

	    start=geom[i,2:3];
	    stop=geom[i+1,2:3];
	    if i==1
	        nstart=1;
	    else
	        nstart=sum(n[1:i-1])+1;
	    end

		node[nstart,:]=[nstart; geom[i,2:3]; 1; 1; 1; 1; 1.0];

	    if (r1==0) & (r2==0) & (r3==0) & (r4==0)
	        #------------------------
	        #SHARP CORNER MODEL
	        for j=1:n[i]-1
	            node[nstart+j,:]=[nstart+j; start+(stop-start)*j/n[i]; 1; 1; 1; 1; 1.0];
	        end
	        #------------------------
	    else
	        #ROUND CORNER MODEL
	        if (d1==0) & (d2==0) #track or unlipped Z geometry
	            #------------------------
	            #UNLIPPED C OR Z SECTION
	            if maximum(i.==[1 3 5]) #use linear interpolation
	                for j=1:n[i]-1
	                    node[nstart+j,:]=[nstart+j; start+(stop-start)*j/n[i]; 1; 1; 1; 1; 1.0];
	                end
	            else #we are in a corner and must be fancier
	                for j=1:n[i]-1
	                    if i==2
	                        r=r1;
							xc=r1;
							zc=r1;
							qstart=π/2;
							dq=π/2*j/n[i];
	                    end
	                    if i==4
	                        r=r3;
							xc=cz*r3;
							zc=r1+h;
							qstart=(1==cz)*π;
							dq=cz*π/2*j/n[i];
	                    end
	                    x2=xc+r*cos(qstart+dq);
	                    z2=zc-r*sin(qstart+dq); #note sign on 2nd term is negative due to z sign convention (down positive)
	                    node[nstart+j,:]=[nstart+j; x2; z2; 1; 1; 1; 1; 1.0];
	                end
	            end
	            #------------------------
	        else
	            #LIPPED C OR Z SECTION
	            #------------------------
	            if maximum(i.==[1 3 5 7 9]) #use linear interpolation
	                for j=1:n[i]-1
	                    node[nstart+j,:]=[nstart+j; start+(stop-start)*j/n[i]; 1; 1; 1; 1; 1.0];
	                end
	            else #we are in a corner and must be fancier
	                for j=1:n[i]-1
	                    if i==2
	                        r=r2;
							xc=r1+b1;
							zc=r2;
							qstart=π/2-q1;
							dq=q1*j/n[i];
	                    end
	                    if i==4
	                        r=r1;
							xc=r1;
							zc=r1;
							qstart=π/2;
							dq=π/2*j/n[i];
	                    end
	                    if i==6
	                        r=r3;
							xc=cz*r3;
							zc=r1+h;
							qstart=(1==cz)*π;
							dq=cz*π/2*j/n[i];
	                    end
	                    if i==8
	                        r=r4;
							xc=cz*(r3+b2);
							zc=r1+h+r3-r4;
							qstart=3*π/2;
							dq=cz*q2*j/n[i];
	                    end
	                    x2=xc+r*cos(qstart+dq);
	                    z2=zc-r*sin(qstart+dq); #note sign on 2nd term is negative due to z sign convention (down positive)
	                    node[nstart+j,:]=[nstart+j; x2; z2; 1; 1; 1; 1; 1.0];
	                end
	            end
	            #------------------------
	        end
	    end
	end



	#GET THE LAST NODE ASSIGNED
	if (r1==0) & (r2==0) & (r3==0) & (r4==0)
	    if (d1==0) & (d2==0)
	        i=4;
	        node[sum(n[1:i-1])+1,:]=[sum(n[1:i-1])+1; geom[i,2:3]; 1; 1; 1; 1; 1.0];
	    else
	        i=6;
	        node[sum(n[1:i-1])+1,:]=[sum(n[1:i-1])+1; geom[i,2:3]; 1; 1; 1; 1; 1.0];
	    end
	else
	    if (d1==0) & (d2==0)
	        i=6;
	        node[sum(n[1:i-1])+1,:]=[sum(n[1:i-1])+1; geom[i,2:3]; 1; 1; 1; 1; 1.0];
	    else
	        i=10;
	        node[sum(n[1:i-1])+1,:]=[sum(n[1:i-1])+1; geom[i,2:3]; 1; 1; 1; 1; 1.0];
	    end
	end

	elem=zeros(sum(n),5)
	for i=1:size(node)[1]-1
   		elem[i,:]=[i i i+1 t 100];
	end

	#set some default properties
	if kipin==1
		prop=[100 29500 29500 0.3 0.3 29500/(2*(1+0.3))];
	else
		prop=[100 203000 203000 0.3 0.3 203000/(2*(1+0.3))];
	end

	#set some default lengths
	big=maximum([h;b1;b2;d1;d2]);
	lengths=exp10.(range(log10(big/10), stop=log10(big*1000), length=50))

	springs=[0]
	constraints=[0]

	return prop,node,elem,lengths,springs,constraints,geom,cz

end

end #module
