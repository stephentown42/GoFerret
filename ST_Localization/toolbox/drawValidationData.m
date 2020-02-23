function drawValidationData(S)

idx = numel(S.modality);
if idx > 80; idx = 80; end

figure('Name','Stim Grid Validation')

sp(1) = subplot(2,3,[1 2]);
hold on
plot(S.modality(1:idx),'-or','parent',sp(1))
plot(S.domMod(1:idx),'-ok','parent',sp(1))
legend('Stimulus','Target')
xlabel('Trial')
ylabel('Modality')

sp(2) = subplot(2,3,3);
imagesc(S.positionGrid, 'parent',sp(2))
xlabel('Speaker Position')
ylabel('LED Position')

sp(3) = subplot(2,3,[4 5]);
hold on
plot(S.LEDs(1:idx),'-ob','parent',sp(3))
plot(S.Speakers(1:idx),'-or','parent',sp(3))
plot(S.targetSpout(1:idx),'xg','parent',sp(3))
ylim([0.5 12.5])
xlabel('Trial')
ylabel('Position')
legend('Visual','Auditory')