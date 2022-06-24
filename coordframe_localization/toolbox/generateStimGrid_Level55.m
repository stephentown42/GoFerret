function stim = generateStimGrid_Level55(stim)

% Alternating modality
% Random location

spouts = [2 10];

% Randomize seed
p = round(rand(1));
q = 1-p;

% Make templates
pq = makeTemplate(spouts, 6, 2, p);
qp = makeTemplate(spouts, 6, 2, q);
p  = makeTemplate(spouts, 3, p, []);
q  = makeTemplate(spouts, 3, q, []);

% Bring it all together
stim.spout    = [p.spout    pq.spout      q.spout        qp.spout];
stim.modality = [p.modality pq.modality   q.modality     qp.modality];
stim.domMod   = [p.domMod   pq.domMod     q.domMod       qp.domMod];

% Final notes
stim.n = numel(stim.modality);
stim.idx = 1;

pause(0.1)


function S = makeTemplate(spouts, n, modality, domMod)

S.modality = repmat(modality,1,n);

idx = 1 + round(rand(n,1));
S.spout = spouts(idx);

if isempty(domMod)
   S.domMod = S.modality;
else
    S.domMod = repmat(domMod,1,n);
end
