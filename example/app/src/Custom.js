// @flow
import React, { PureComponent } from 'react';
import { StyleSheet, View, Modal, Button, TouchableOpacity, Text } from 'react-native';
import { CreditCardInput } from 'react-native-credit-card-input';
import { compose, withState, withProps } from 'recompose';
import stripe from './stripe';

type Props = {
  openCardModal: () => any,
  closeCardModal: () => any,
  isCardModalOpened: boolean,
};

const CloseButton = props => (
  <TouchableOpacity onPress={props.onPress} activeOpacity={0.7} style={styles.closeButton}>
    <Text style={styles.closeButtonText}>X</Text>
  </TouchableOpacity>
);

class Manual extends PureComponent<Props> {
  render() {
    return (
      <View style={styles.container}>
        <Button title="Add a card" onPress={this.props.openCardModal} />
        <Modal
          visible={this.props.isCardModalOpened}
          onRequestClose={this.closeCardModal}
          animationType="slide"
        >
          <View style={styles.modal}>
            <CloseButton onPress={this.props.closeCardModal} />
            <CreditCardInput onChange={this.props.onCardEdit} />
            <View style={styles.buttonContainer}>
              <Button style={styles.button} title="Add Card (token)" onPress={this.props.addCardWithToken} />
              <Button style={styles.button} title="Add Card (source)" onPress={this.props.addCardWithSource} />
            </View>
          </View>
        </Modal>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  modal: {},
  closeButton: {
    paddingHorizontal: 20,
    paddingVertical: 30,
  },
  closeButtonText: {
    fontSize: 22,
    fontWeight: 'bold',
  },
  buttonContainer: {
    marginTop: 16,
    flexDirection: "row",
    justifyContent: "space-around"
  },
  button: {
    padding: 16
  }
});

export default compose(
  withState('isCardModalOpened', 'setIsCardModalOpened', false),
  withState('creditCard', 'onCardEdit', null),
  withProps(({ setIsCardModalOpened, creditCard }) => ({
    openCardModal: () => setIsCardModalOpened(true),
    closeCardModal: () => setIsCardModalOpened(false),
    addCardWithToken: () => {
      console.log('got here');
      stripe.addCardWithToken(creditCard);
      setIsCardModalOpened(false);
    },
    addCardWithSource: () => {
      stripe.addCardWithSource(creditCard);
      setIsCardModalOpened(false);
    }
  }))
)(Manual);
