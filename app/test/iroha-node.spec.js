/*!
 * Diva IrohaNode Test suite
 * Copyright(c) 2020 Konrad Baechler, https://diva.exchange
 * GPL3 Licensed
 */
'use strict'

import { describe, it } from 'mocha'
import { IrohaNode } from '../src/iroha-node'

import * as chai from 'chai'
const assert = chai.assert

/**
 * Project: diva
 * Context: iroha
 */
describe('//diva// /iroha', () => {
  describe('IrohaNode', () => {
    it('Error, invalid port', () => {
      assert.throws(() => { IrohaNode.make('holodeck0', 1) }, 'invalid port')
    })
  })
})
