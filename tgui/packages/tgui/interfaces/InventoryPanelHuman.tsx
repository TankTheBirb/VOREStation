import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import { Button, LabeledList, Section } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

type Data = {
  slots: slot[];
  specialSlots: slot[];
  internals: string;
  internalsValid: BooleanLike;
  sensors: BooleanLike;
  handcuffed: BooleanLike;
  handcuffedParams: { slot: number };
  legcuffed: BooleanLike;
  legcuffedParams: { slot: number };
  accessory: BooleanLike;
};

type slot = {
  name: string;
  item: string;
  act: string;
  params: { slot: number };
};

export const InventoryPanelHuman = (props) => {
  const { act, data } = useBackend<Data>();

  const {
    slots,
    specialSlots,
    internalsValid,
    sensors,
    handcuffed,
    handcuffedParams,
    legcuffed,
    legcuffedParams,
    accessory,
  } = data;

  return (
    <Window width={400} height={600}>
      <Window.Content scrollable>
        <Section>
          <LabeledList>
            {slots &&
              slots.length &&
              slots.map((slot) => (
                <LabeledList.Item key={slot.name} label={slot.name}>
                  <Button
                    mb={-1}
                    icon={slot.item ? 'hand-paper' : 'gift'}
                    onClick={() => act(slot.act, slot.params)}
                  >
                    {slot.item || 'Nothing'}
                  </Button>
                </LabeledList.Item>
              ))}
            <LabeledList.Divider />
            {specialSlots &&
              specialSlots.length &&
              specialSlots.map((slot) => (
                <LabeledList.Item key={slot.name} label={slot.name}>
                  <Button
                    mb={-1}
                    icon={slot.item ? 'hand-paper' : 'gift'}
                    onClick={() => act(slot.act, slot.params)}
                  >
                    {slot.item || 'Nothing'}
                  </Button>
                </LabeledList.Item>
              ))}
          </LabeledList>
        </Section>
        <Section title="Actions">
          <Button
            fluid
            icon="running"
            onClick={() => act('targetSlot', { slot: 'splints' })}
          >
            Remove Splints
          </Button>
          <Button
            fluid
            icon="hand-paper"
            onClick={() => act('targetSlot', { slot: 'pockets' })}
          >
            Empty Pockets
          </Button>
          <Button
            fluid
            icon="socks"
            onClick={() => act('targetSlot', { slot: 'underwear' })}
          >
            Remove or Replace Underwear
          </Button>
          {(internalsValid && (
            <Button
              fluid
              icon="lungs"
              onClick={() => act('targetSlot', { slot: 'internals' })}
            >
              Set Internals
            </Button>
          )) ||
            null}
          {(sensors && (
            <Button
              fluid
              icon="book-medical"
              onClick={() => act('targetSlot', { slot: 'sensors' })}
            >
              Set Sensors
            </Button>
          )) ||
            null}
          {(handcuffed && (
            <Button
              fluid
              color="bad"
              icon="unlink"
              onClick={() => act('targetSlot', handcuffedParams)}
            >
              Handcuffed
            </Button>
          )) ||
            null}
          {(legcuffed && (
            <Button
              fluid
              color="bad"
              icon="unlink"
              onClick={() => act('targetSlot', legcuffedParams)}
            >
              Legcuffed
            </Button>
          )) ||
            null}
          {(accessory && (
            <Button
              fluid
              color="bad"
              icon="unlink"
              onClick={() => act('targetSlot', { slot: 'tie' })}
            >
              Remove Accessory
            </Button>
          )) ||
            null}
        </Section>
      </Window.Content>
    </Window>
  );
};
