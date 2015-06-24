clear all
close all
% clf
I=imread('exemple1.JPG');
Indg=rgb2gray(I); %NdG

[l,c]=size(Indg); %Taille matrice Indg


%----Lissage------------
G = fspecial('gaussian',[9 9],3); %creation filtre gaussien


IG = imfilter(Indg,G,'symmetric','same','conv'); %filtrage gaussien
%--------------------------

%------------Calcul du gradient-----
%Matrices grad
IX=zeros(l,c);%grad horizon
IY=zeros(l,c);%grad vert
IXY=zeros(l,c);%norme grad

%Sobel 3x3
for i=2:l-1
    for j=2:c-1
        IX(i,j)=-(-double(IG(i-1,j-1))-2*double(IG(i,j-1))-double(IG(i+1,j-1))+double(IG(i-1,j+1))+2*double(IG(i,j+1))+double(IG(i+1,j+1)))/8;
        IY(i,j)=-(-2*double(IG(i-1,j))+2*double(IG(i+1,j))-double(IG(i-1,j-1))+double(IG(i+1,j-1))-double(IG(i-1,j+1))+double(IG(i+1,j+1)))/8;
        IXY(i,j)=sqrt(((IX(i,j))^2)+((IY(i,j))^2));
    end
end

%-------Binarisation----
%Seuillage par hysteresis
Ibin=zeros(l,c);%binaire
Sh=9;
Sb=6;

for i=1:l
    for j=1:c
        
        if IXY(i,j)>=Sh %Seuil : gradient > Sh
            Ibin(i,j)=255;
           
        elseif IXY(i,j)<Sb %Seuil : gradient < Sb
            Ibin(i,j)=0;
        end
        
     end
end

for p=1:20
    for i=1:l
        for j=1:c
            if IXY(i,j)<Sh && IXY(i,j)>=Sb %Seuil : Sh > gradient > Sb
                % Extraction des 8 pixels voisins
                vect = [Ibin(i-1,j-1:j+1) Ibin(i, j-1) Ibin(i, j+1) Ibin(i+1,j-1:j+1)];
                if max(vect)==255
                    Ibin(i,j)=255;
                else
                    Ibin(i,j)=0;
                end
            end  
        end
    end
end  





%----------Identification des régions-----
[L,num]=bwlabel(Ibin,8);


t=regionprops(L, 'area'); %info sur les régions
taille=zeros(num,1);
for g=1:num
    taille(g,1)=t(g,1).Area(1,1);   %On extrait la taille des régions
end


%-----Effacement des petites régions------
Ifer=zeros(l,c);
for i=1:l
    for j=1:c
        for k=1
            if Ibin(i,j)==0
                Ifer(i,j)=Ibin(i,j);
            else
                for w=1:num 
                    if L(i,j)==w
                        if taille(w,1)<=500 %supression des regions de moins de 500 px
                          Ifer(i,j)=0;
                        else
                          Ifer(i,j,k)=Ibin(i,j);
                        end
                    end
                end
            end
        end
    end
end

%-----Fermeture----------
se = strel('square',4);%motif carré de coté 4
Ifer2=imclose(Ifer,se); %fermeture

%----------Deuxième identification des régions-----
[L2,num2]=bwlabel(Ifer2,8);
t2=regionprops(L2, 'area');
taille2=zeros(num2,1);
for g=1:num2
    taille2(g,1)=t2(g,1).Area(1,1);   
end



%-----------Refaire l'image (fissure en rouge)------------
Ifin=zeros(l,c,3);%matrice finale

Ifin=uint8(Ifin);

for i=1:l
    for j=1:c
        for k=1
            if Ifer2(i,j)==0
                Ifin(i,j,:)=I(i,j,:);
            else
                Ifin(i,j,k)=255;
            end
        end
    end
end

%---------------------------Affichages----------------------------------

figure, imagesc(I), title('Début'); %Affichage de l'image de base

figure, imagesc(Indg), title('NdG'); %Affichage de l'image NdG
colormap(gray)
figure, imagesc(IG), title('Lissage'); %Affichage de l'image lissée
colormap(gray)
figure, imagesc(IXY), title('Norme gradient'); %Affichage de la norme du gradient

figure, imagesc(Ibin), title('Binarisation'); %Affichage l'image binaire
colormap(gray)

figure, imagesc(Ifer), title('Effacement'); %Affichage l'image apres effacement des petites régions
colormap(gray)

figure, imagesc(Ifer2), title('Fermeture'); %Affichage l'image fermée
colormap(gray)

figure, imagesc(Ifin), title('Refonte'); %Affichage l'image refaite

figure, imagesc(L2), title('Etape finale'); %Affichage l'image labelisée