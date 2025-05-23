import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Section, Stack, Tabs } from 'tgui-core/components';

import { OperatingComputerOptions } from './OperatingComputerOptions';
import { OperatingComputerPatient } from './OperatingComputerPatient';
import { OperatingComputerUnoccupied } from './OperatingComputerUnoccupied';
import type { Data } from './types';

export const OperatingComputer = (props) => {
  const { act, data } = useBackend<Data>();
  const { hasOccupant, choice, occupant } = data;
  let body;
  if (!choice) {
    body = hasOccupant ? (
      <OperatingComputerPatient occupant={occupant} />
    ) : (
      <OperatingComputerUnoccupied />
    );
  } else {
    body = <OperatingComputerOptions />;
  }
  return (
    <Window width={650} height={455}>
      <Window.Content>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={!choice}
                icon="user"
                onClick={() => act('choiceOff')}
              >
                Patient
              </Tabs.Tab>
              <Tabs.Tab
                selected={!!choice}
                icon="cog"
                onClick={() => act('choiceOn')}
              >
                Options
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            <Section fill scrollable>
              {body}
            </Section>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
